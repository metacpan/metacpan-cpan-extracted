package DBIO::PostgreSQL::Diff;
# ABSTRACT: Compare two introspected PostgreSQL models

use strict;
use warnings;

use base 'DBIO::Diff::Base';


use DBIO::PostgreSQL::Diff::Schema    ();
use DBIO::PostgreSQL::Diff::Table     ();
use DBIO::PostgreSQL::Diff::Column    ();
use DBIO::PostgreSQL::Diff::Type      ();
use DBIO::PostgreSQL::Diff::Index     ();
use DBIO::PostgreSQL::Diff::Function  ();
use DBIO::PostgreSQL::Diff::Trigger   ();
use DBIO::PostgreSQL::Diff::Policy    ();
use DBIO::PostgreSQL::Diff::Extension ();

my %_REGISTRY = (
  extensions => 'DBIO::PostgreSQL::Diff::Extension',
  schemas    => 'DBIO::PostgreSQL::Diff::Schema',
  types      => 'DBIO::PostgreSQL::Diff::Type',
  functions  => 'DBIO::PostgreSQL::Diff::Function',
  tables     => 'DBIO::PostgreSQL::Diff::Table',
  columns    => 'DBIO::PostgreSQL::Diff::Column',
  indexes    => 'DBIO::PostgreSQL::Diff::Index',
  triggers   => 'DBIO::PostgreSQL::Diff::Trigger',
  policies   => 'DBIO::PostgreSQL::Diff::Policy',
);

my @_ORDER = qw(
  extensions schemas types functions tables columns indexes triggers policies
);

# Trailing context each table-aware diff class needs after its own
# (source, target) section pair. Diff::Table builds full CREATE TABLE
# statements and therefore needs the *column* data; Diff::Column and
# Diff::Policy need the *table* list for schema/table context; Diff::Index
# needs the *table* list to detect which tables are being dropped in the
# same pass, so it can suppress standalone DROP INDEX ops that DROP TABLE
# ... CASCADE already covers (karr #32).
my %_AUX_SECTION = (
  tables   => 'columns',
  columns  => 'tables',
  indexes  => 'tables',
  policies => 'tables',
);

sub _diff_registry { %_REGISTRY }
sub _diff_order    { @_ORDER    }


sub register_diff_class {
  my ($class, %args) = @_;
  my $key      = $args{model_key} or die 'model_key required';
  my $diff_cls = $args{class}     or die 'class required';
  my $position = $args{position};

  $_REGISTRY{$key} = $diff_cls;
  @_ORDER = grep { $_ ne $key } @_ORDER;

  if (!defined $position) {
    push @_ORDER, $key;
  } elsif ($position =~ /\Aafter:(.+)\z/) {
    my $anchor = $1;
    my ($i) = grep { $_ORDER[$_] eq $anchor } 0..$#_ORDER;
    die "position anchor '$anchor' not found in diff order" unless defined $i;
    splice @_ORDER, $i + 1, 0, $key;
  } elsif ($position =~ /\Abefore:(.+)\z/) {
    my $anchor = $1;
    my ($i) = grep { $_ORDER[$_] eq $anchor } 0..$#_ORDER;
    die "position anchor '$anchor' not found in diff order" unless defined $i;
    splice @_ORDER, $i, 0, $key;
  } else {
    die "invalid position '$position' — use 'after:KEY' or 'before:KEY'";
  }
}

sub _build_operations {
  my ($self) = @_;
  my @ops;

  for my $key (@_ORDER) {
    my $diff_cls = $_REGISTRY{$key} or next;
    next unless exists $self->source->{$key} || exists $self->target->{$key};

    my @extra;
    if (my $aux = $_AUX_SECTION{$key}) {
      @extra = (
        $self->source->{$aux} // {},
        $self->target->{$aux} // {},
      );
    }

    push @ops, $diff_cls->diff(
      $self->source->{$key} // {},
      $self->target->{$key} // {},
      @extra,
    );
  }

  return \@ops;
}


# Map native_type strings that differ between the adapter output and what
# pg_catalog.format_type actually reports back.
my %_PG_FORMAT_TYPE = (
  'timestamptz' => 'timestamp with time zone',
);

# Render a default value in the same string form that pg_get_expr reports
# back from pg_attrdef, so the synthesized target model round-trips against
# the live (introspected) source. Returns undef when there is no default.
#
#   $c->{default} shape (from DBIO::Schema::Type::canonical_column):
#     undef         -- no default
#     \"now()"      -- SCALAR ref holding a raw PG expression
#     \"5"          -- SCALAR ref holding a numeric literal
#     "draft"       -- plain string (a text/varchar literal in single quotes)
#
# pg_get_expr output for common cases:
#     text 'draft'   -> "'draft'::text"            (string + ::textype)
#     numeric 42     -> "42"                        (number, no cast)
#     now()          -> "now()"                     (expression, unchanged)
#     nextval seq    -> "nextval('schema.seq'::regclass)"
sub _format_pg_default {
  my ($default, $data_type) = @_;
  return undef unless defined $default;

  my $expr = ref $default eq 'SCALAR' ? $$default : $default;
  return undef unless defined $expr && length $expr;
  $expr =~ s/^\s+|\s+$//g;

  # nextval() -- left untouched (matches pg_get_expr for IDENTITY-adjacent cols,
  # though those are handled via $identity above and not via default).
  return $expr if $expr =~ /\bnextval\s*\(/i;

  # Already a quoted string (e.g. DDL-emitted literal). Pass through as-is so
  # any embedded ::cast is preserved.
  return $expr if $expr =~ /^['"]/;

  # Already a quoted expression like 'now()' as a SCALAR ref string content
  # of a non-string column -- common case: default_value => \'now()'.
  # If it has parens or ::cast, leave alone.
  return $expr if $expr =~ /[()]/ || $expr =~ /::/;

  # Pure number or numeric expression -- PG renders numeric defaults
  # as a quoted literal with an explicit cast (e.g. '0'::bigint), not as
  # a bare number. The column type is *not* implied by the value.
  if ($expr =~ /^-?\d+(?:\.\d+)?\z/) {
    my $cast = $data_type // 'text';
    $cast = "timestamp with time zone" if $cast eq 'timestamptz';
    return sprintf(q{'%s'} . '::%s', $expr, $cast);
  }

  # Boolean literals -- PG renders as 'true' / 'false' / 'null' (no cast).
  return lc $expr if $expr =~ /^(?:true|false|null)\z/i;

  # Fallback: treat as a string literal, quoting and casting to the column
  # type. pg_get_expr appends '::textype' (the column's data_type string as
  # format_type renders it). Use the already-normalized $data_type.
  my $cast = $data_type // 'text';
  $cast = "timestamp with time zone" if $cast eq 'timestamptz';
  return sprintf(q{'%s'} . '::%s', $expr, $cast);
}

sub target_from_compiled {
  my ($class, $compiled) = @_;
  my (%tables, %columns, %indexes);

  # The public schema always exists in PostgreSQL; include it so the schema
  # diff does not emit a spurious DROP SCHEMA public.
  my %schemas = ( public => {} );

  for my $tname (keys %{ $compiled->{tables} // {} }) {
    my $t   = $compiled->{tables}{$tname};
    my $key = "public.$tname";

    $tables{$key} = {
      schema_name => 'public',
      table_name  => $tname,
      kind        => 'r',
    };

    my @cols;
    my @pk_cols;
    for my $c (@{ $t->{columns} // [] }) {
      my $native = $c->{native_type};
      my $data_type = $_PG_FORMAT_TYPE{$native} // $native;

      my $identity      = undef;
      my $default_value = _format_pg_default($c->{default}, $data_type);

      if ($c->{auto_increment} && $c->{is_pk}) {
        # Deploy as GENERATED ALWAYS AS IDENTITY; PG reports identity='a' and no default.
        $identity      = 'a';
        $default_value = undef;
      }
      elsif ($c->{auto_increment}) {
        # Non-PK auto-increment: DDL.pm emits GENERATED BY DEFAULT AS IDENTITY,
        # and PG reports attidentity='d' with no default expression.
        $identity      = 'd';
        $default_value = undef;
      }

      push @cols, {
        column_name   => $c->{column_name},
        data_type     => $data_type,
        not_null      => ($c->{not_null} ? 1 : 0),
        default_value => $default_value,
        identity      => $identity,
        generated     => undef,
      };

      push @pk_cols, $c->{column_name} if $c->{is_pk};
    }
    $columns{$key} = \@cols;

    # PostgreSQL automatically creates a primary key index named <table>_pkey.
    # Include it in the target so the index diff does not flag it as dropped.
    # The definition string matches what pg_get_indexdef returns, enabling
    # the definition-based comparison in Diff::Index.
    if (@pk_cols) {
      my $pkey_name = "${tname}_pkey";
      my $cols_str  = join ', ', @pk_cols;
      my $definition = "CREATE UNIQUE INDEX $pkey_name ON public.$tname USING btree ($cols_str)";
      $indexes{$key}{$pkey_name} = {
        index_name    => $pkey_name,
        access_method => 'btree',
        is_unique     => 1,
        is_primary    => 1,
        is_valid      => 1,
        definition    => $definition,
        predicate     => undef,
        expressions   => undef,
        columns         => \@pk_cols,
        include_columns => [],
        storage_params  => {},
      };
    }
  }

  return {
    tables           => \%tables,
    columns          => \%columns,
    schemas          => \%schemas,
    extensions       => {},
    types            => {},
    functions        => {},
    indexes          => \%indexes,
    triggers         => {},
    policies         => {},
    sequences        => {},
    foreign_keys     => {},
    check_constraints => {},
  };
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Diff - Compare two introspected PostgreSQL models

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

C<DBIO::PostgreSQL::Diff> compares two introspected PostgreSQL database models
(as produced by L<DBIO::PostgreSQL::Introspect>) and produces a list of
structured diff operations. These operations can then be rendered to SQL or a
human-readable summary.

    my $diff = DBIO::PostgreSQL::Diff->new(
        source => $current_model,
        target => $desired_model,
    );

    if ($diff->has_changes) {
        print $diff->as_sql;
        print $diff->summary;
    }

Diff operations are generated in dependency order: extensions first, then
schemas, types, functions, tables, columns, indexes, triggers, and policies.
That same order is used for both C<summary> and C<as_sql>, so review output and
executable output stay aligned.

=head1 METHODS

=head2 register_diff_class

    DBIO::PostgreSQL::Diff->register_diff_class(
        model_key => 'spatial_refs',
        class     => 'DBIO::PostgreSQL::PostGIS::Diff::SpatialRef',
        position  => 'after:indexes',
    );

Register a Diff class for a model key. Use C<position> (C<after:KEY> or C<before:KEY>) to control ordering.

=head2 target_from_compiled

    my $target = DBIO::PostgreSQL::Diff->target_from_compiled($compiled_model);

Translates the neutral model from L<DBIO::Schema::ModelCompiler> into the
PostgreSQL introspect-shaped model that C<diff> consumes.

The compiled model uses C<native_type> (as produced by
L<DBIO::PostgreSQL::Adapter>). This method translates that into the exact
C<data_type> strings that L<DBIO::PostgreSQL::Introspect::Columns> returns
(i.e. whatever C<pg_catalog.format_type> reports), keys tables as
C<"public.$table_name">, and populates all top-level sections the Diff
engine dereferences so that no spurious diffs arise from missing keys.

Auto-increment primary-key columns are mapped to C<identity = 'a'>
(C<GENERATED ALWAYS AS IDENTITY>), which is the canonical DBIO convention
for integer PKs in PostgreSQL.

=seealso

=over 4

=item * L<DBIO::PostgreSQL::Deploy> - orchestrates introspection and diff

=item * L<DBIO::PostgreSQL::Introspect> - produces the models being compared

=item * L<DBIO::PostgreSQL::Diff::Schema>

=item * L<DBIO::PostgreSQL::Diff::Table>

=item * L<DBIO::PostgreSQL::Diff::Column>

=item * L<DBIO::PostgreSQL::Diff::Type>

=item * L<DBIO::PostgreSQL::Diff::Index>

=item * L<DBIO::PostgreSQL::Diff::Function>

=item * L<DBIO::PostgreSQL::Diff::Trigger>

=item * L<DBIO::PostgreSQL::Diff::Policy>

=item * L<DBIO::PostgreSQL::Diff::Extension>

=back

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
