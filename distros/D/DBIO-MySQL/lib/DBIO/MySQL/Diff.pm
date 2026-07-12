package DBIO::MySQL::Diff;
# ABSTRACT: Compare two introspected MySQL/MariaDB models

use strict;
use warnings;

use base 'DBIO::Diff::Base';

use DBIO::MySQL::Diff::Table;
use DBIO::MySQL::Diff::Column;
use DBIO::MySQL::Diff::Index;
use DBIO::MySQL::Diff::ForeignKey;
use DBIO::MySQL::Adapter;

my $ADAPTER = DBIO::MySQL::Adapter->new;



# Parse adapter native_type (e.g. "BIGINT", "CHAR(32)", "DECIMAL(10,2)") into
# the lowercase data_type + column_type pair that information_schema reports.
sub _native_to_mysql_types {
  my ($native) = @_;
  my $lc = lc $native;

  # BIGINT → bigint / bigint(20)
  return ('bigint', 'bigint(20)') if $lc eq 'bigint';

  # TINYINT(1) → tinyint / tinyint(1)
  return ('tinyint', 'tinyint(1)') if $lc eq 'tinyint(1)';

  # DOUBLE → double / double
  return ('double', 'double') if $lc eq 'double';

  # LONGTEXT → longtext / longtext
  return ('longtext', 'longtext') if $lc eq 'longtext';

  # LONGBLOB → longblob / longblob
  return ('longblob', 'longblob') if $lc eq 'longblob';

  # DATETIME → datetime / datetime
  return ('datetime', 'datetime') if $lc eq 'datetime';

  # CHAR(n) → char / char(n)
  if ($lc =~ /\Achar\((\d+)\)\z/) {
    return ('char', "char($1)");
  }

  # DECIMAL(p,s) → decimal / decimal(p,s)
  if ($lc =~ /\Adecimal\((\d+),(\d+)\)\z/) {
    return ('decimal', "decimal($1,$2)");
  }

  # Bare DECIMAL (no precision)
  return ('decimal', 'decimal') if $lc eq 'decimal';

  # Fallback: lowercase as-is for both
  (my $bare = $lc) =~ s/\(.*//;
  return ($bare, $lc);
}

# Types whose charset/collation is NULL in information_schema (binary/numeric/datetime).
# Lives in DBIO::MySQL::Adapter as %NO_CHARSET, exposed via $ADAPTER->no_charset_for.

sub target_from_compiled {
  my ($class, $compiled) = @_;
  my (%tables, %columns);

  for my $tname (keys %{ $compiled->{tables} // {} }) {
    my $t = $compiled->{tables}{$tname};
    $tables{$tname} = { table_name => $tname };

    my @cols;
    for my $c (@{ $t->{columns} // [] }) {
      my ($data_type, $column_type) = _native_to_mysql_types($c->{native_type});

      # charset/collation: leave undef for binary/numeric types so that the
      # comparison (_norm returns '') equals the undef in the live introspect.
      # For text/char types the live DB will have a server-assigned charset;
      # we also leave undef here — see ESCALATION NOTE below.
      my ($charset, $collation) = (undef, undef);
      if ($ADAPTER->no_charset_for($c->{native_type})) {
        $charset = $collation = undef;   # already undef; explicit for clarity
      }

      # A portable schema prescribes a default only when it declares one; when it
      # does not, leave default_value undef so the always-on desired-state
      # contract in DBIO::Diff::Compare skips it and leaves whatever the live
      # column reports alone. information_schema reports SQL NULL (-> undef) as
      # column_default for a nullable column with no explicit DEFAULT clause, so
      # synthesising a literal string 'NULL' here produced a phantom MODIFY of
      # every such column against that undef.
      my $not_null = ($c->{not_null} ? 1 : 0);
      my $default  = $c->{default};

      push @cols, {
        column_name       => $c->{column_name},
        data_type         => $data_type,
        column_type       => $column_type,
        not_null          => $not_null,
        default_value     => $default,
        is_pk             => ($c->{is_pk} ? 1 : 0),
        is_auto_increment => ($c->{auto_increment} ? 1 : 0),
        character_set     => $charset,
        collation         => $collation,
      };
    }
    $columns{$tname} = \@cols;
  }

  # ESCALATION NOTE: MySQL/MariaDB assigns character_set and collation from the
  # database/server defaults to every text-family column (CHAR, VARCHAR, TEXT,
  # LONGTEXT, …). A portable schema does not prescribe charset/collation, so
  # target_from_compiled cannot derive these values from the schema alone.
  # changed_column_fields() compares character_set and collation; leaving them undef in
  # the target produces phantom diffs for text columns whenever the live DB
  # reports a non-null charset (e.g. utf8mb4 / utf8mb4_uca1400_ai_ci on MariaDB
  # 11.8). This is a design question for the controller: should the desired-state
  # diff ignore attributes the target leaves unspecified?

  return {
    tables       => \%tables,
    columns      => \%columns,
    indexes      => {},
    foreign_keys => {},
  };
}

sub _build_operations {
  my ($self) = @_;
  my @ops;

  push @ops, DBIO::MySQL::Diff::Table->diff(
    $self->source->{tables}, $self->target->{tables},
    $self->target->{columns}, $self->target->{foreign_keys},
  );
  push @ops, DBIO::MySQL::Diff::Column->diff(
    $self->source->{columns}, $self->target->{columns},
    $self->source->{tables},  $self->target->{tables},
  );
  push @ops, DBIO::MySQL::Diff::Index->diff(
    $self->source->{indexes}, $self->target->{indexes},
    $self->source->{tables},  $self->target->{tables},
  );
  push @ops, DBIO::MySQL::Diff::ForeignKey->diff(
    $self->source->{foreign_keys}, $self->target->{foreign_keys},
    $self->source->{tables},       $self->target->{tables},
  );

  return \@ops;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MySQL::Diff - Compare two introspected MySQL/MariaDB models

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

C<DBIO::MySQL::Diff> compares two introspected MySQL/MariaDB models
(as produced by L<DBIO::MySQL::Introspect>) and produces a list of
structured diff operations.

    my $diff = DBIO::MySQL::Diff->new(
        source => $current_model,
        target => $desired_model,
    );

    if ($diff->has_changes) {
        print $diff->as_sql;
        print $diff->summary;
    }

Operations are emitted in dependency order: tables, columns, indexes,
foreign keys.

=head1 METHODS

=head2 target_from_compiled

    my $target = DBIO::MySQL::Diff->target_from_compiled($compiled_model);

Translates the neutral model from L<DBIO::Schema::ModelCompiler> into the
MySQL/MariaDB introspect-shaped model that C<diff> consumes.

The compiled model uses C<native_type> (as produced by L<DBIO::MySQL::Adapter>,
e.g. C<BIGINT>, C<CHAR(32)>, C<TINYINT(1)>). This method maps those into the
exact lowercase C<data_type> and parameterised C<column_type> strings that
L<DBIO::MySQL::Introspect::Columns> returns from C<information_schema.columns>.

C<character_set> and C<collation> are left C<undef> on non-text columns (numeric,
binary, datetime) to match what MariaDB/MySQL reports for those types. For text
and char columns the server assigns a charset/collation from the database
default; since a portable schema does not prescribe a charset, those fields are
also left C<undef> in the target so the diff engine sees both sides as empty and
does not emit phantom changes. See ESCALATION NOTE in the source.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
