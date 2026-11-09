package DBIO::ClickHouse::Introspect;
# ABSTRACT: Introspect a ClickHouse database via the system.* catalog

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Introspect::Base';

use DBIO::ClickHouse::Introspect::Tables;
use DBIO::ClickHouse::Introspect::Columns;
use DBIO::ClickHouse::Introspect::Indexes;
use DBIO::ClickHouse::Introspect::Util ();



sub database { $_[0]->{database} }

sub _build_model {
  my ($self) = @_;
  my $dbh      = $self->dbh;
  my $database = $self->database;

  my $tables = DBIO::ClickHouse::Introspect::Tables->fetch($dbh, $database);

  return {
    tables  => $tables,
    columns => DBIO::ClickHouse::Introspect::Columns->fetch($dbh, $tables, $database),
    data_skipping_indexes =>
      DBIO::ClickHouse::Introspect::Indexes->fetch($dbh, $tables, $database),
    indexes      => {},
    foreign_keys => {},
  };
}


sub table_columns_info {
  my ($self, $key) = @_;

  my %info;
  for my $col (@{ $self->model->{columns}{$key} || [] }) {
    my $type = DBIO::ClickHouse::Introspect::Util->normalize_type($col->{data_type});

    my %column = (
      data_type   => $type->{data_type},
      # Deliberately NOT the base's `($col->{not_null} || $col->{is_pk}) ? 0 : 1`
      # (core k126). That fold repairs models where the engine reports the
      # NOT NULL attribute and the key constraint separately, so a key column
      # arrives with not_null = 0 -- SQLite's PRAGMA does exactly that. There is
      # no such gap here: nullability is part of the ClickHouse type
      # (Nullable(T)) and is read straight off it, which is also the only thing
      # DBIO::ClickHouse::Introspect::Columns derives not_null from. The fold
      # could therefore only ever change an answer for a key column the server
      # really did declare Nullable (MergeTree `SETTINGS allow_nullable_key = 1`),
      # and there it would claim NOT NULL for a column that holds NULLs -- which
      # breaks the DDL <-> Introspect round-trip this class exists to keep, since
      # the redeploy would silently drop the Nullable wrapper.
      is_nullable => $type->{is_nullable},
    );
    $column{size} = $type->{size} if defined $type->{size};

    my %extra = %{ $type->{extra} || {} };
    $self->_normalize_default(\%column, \%extra, $col);
    $column{extra} = \%extra if keys %extra;

    $info{ $col->{column_name} } = \%column;
  }

  return \%info;
}

# The inverse of DBIO::ClickHouse::DDL::_column_default: a plain scalar
# default_value renders as a quoted string literal and a SCALAR ref renders
# verbatim, so a quoted literal comes back as a plain scalar and everything
# else as a SCALAR ref. This is deliberately stricter than the DuckDB
# introspector, which turns bare numbers into plain scalars too -- here that
# would re-render `DEFAULT 0` as `DEFAULT '0'` and change the emitted DDL.
sub _normalize_default {
  my ($self, $column, $extra, $col) = @_;

  my $expression = $col->{default_value};
  return unless defined $expression && length $expression;

  # MATERIALIZED / ALIAS / EPHEMERAL are not DEFAULT: the value is computed or
  # not stored at all. Emitting them as default_value would turn them into a
  # plain DEFAULT on the next deploy and change the column's semantics, so they
  # are recorded in extra and left out of default_value.
  my $kind = uc($col->{default_kind} // 'DEFAULT');
  if ($kind ne 'DEFAULT') {
    $extra->{default_kind}       = $kind;
    $extra->{default_expression} = $expression;
    return;
  }

  # generateUUIDv4() on a UUID column is this driver's only surrogate identity
  # (see DBIO::ClickHouse::DDL: there are no sequences and no identity
  # columns), so it maps back to is_auto_increment and no default_value --
  # exactly what the DDL layer consumes. retrieve_on_insert is deliberately
  # NOT set: ClickHouse has no RETURNING and no last_insert_id, so DBIO could
  # not fetch the generated value back.
  if (($column->{data_type} // '') eq 'uuid'
      && $expression =~ /\Agenerate(?:UUIDv4|UUIDv7)\(\s*\)\z/) {
    $column->{is_auto_increment} = 1;
    return;
  }

  my $literal = DBIO::ClickHouse::Introspect::Util->unquote_string($expression);
  if (defined $literal) {
    $column->{default_value} = $literal;
    return;
  }

  my $raw = $expression;
  $column->{default_value} = \$raw;
}


sub table_uniq_info { return [] }


sub table_fk_info { return [] }


sub table_comment {
  my ($self, $key) = @_;
  my $comment = ($self->model->{tables}{$key} || {})->{comment};
  return (defined $comment && length $comment) ? $comment : undef;
}


sub column_comment {
  my ($self, $key, $column_name) = @_;
  for my $col (@{ $self->model->{columns}{$key} || [] }) {
    next unless $col->{column_name} eq $column_name;
    return $col->{comment};
  }
  return undef;
}


sub view_definition {
  my ($self, $key) = @_;
  return undef unless $self->table_is_view($key);

  my $sql = q{
    SELECT create_table_query
    FROM system.tables
    WHERE database = %s AND name = ?
  };
  my @bind;
  if (defined $self->database) {
    $sql = sprintf $sql, '?';
    push @bind, $self->database;
  }
  else {
    $sql = sprintf $sql, 'currentDatabase()';
  }
  push @bind, $key;

  my ($create) = $self->dbh->selectrow_array($sql, undef, @bind);
  return DBIO::ClickHouse::Introspect::Util->view_select($create);
}


sub result_class_extra_statements {
  my ($self, $key) = @_;

  my $table = $self->model->{tables}{$key} or return ();
  return () if ($table->{kind} // '') eq 'view';

  my %options;
  $options{engine} = $table->{engine_expression}
    if defined $table->{engine_expression} && length $table->{engine_expression};

  $options{order_by} = [ map { _key_entry($_) } @{ $table->{sorting_key_entries} || [] } ];

  $options{partition_by} = $table->{partition_key}
    if defined $table->{partition_key} && length $table->{partition_key};

  $options{primary_key} = [ map { _key_entry($_) } @{ $table->{primary_key_entries} || [] } ]
    if _key_differs($table->{primary_key_entries}, $table->{sorting_key_entries});

  return ([ clickhouse_table => \%options ]);
}

# A bare column name stays a string; anything else is raw SQL and has to be a
# SCALAR ref, or clickhouse_table would quote cityHash64(id) as an identifier.
sub _key_entry {
  my ($entry) = @_;
  return $entry if $entry =~ /\A\w+\z/;
  my $expression = $entry;
  return \$expression;
}

sub _key_differs {
  my ($left, $right) = @_;
  $left  ||= [];
  $right ||= [];
  return 1 if @$left != @$right;
  for my $i (0 .. $#$left) {
    return 1 if $left->[$i] ne $right->[$i];
  }
  return 0;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::ClickHouse::Introspect - Introspect a ClickHouse database via the system.* catalog

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

C<DBIO::ClickHouse::Introspect> reads the live state of a ClickHouse database
over the MySQL wire protocol and returns a model hashref. It is the reverse of
L<DBIO::ClickHouse::DDL>: what the DDL layer renders from a DBIO
C<column_info>, this returns from the server state.

    my $intro = DBIO::ClickHouse::Introspect->new(dbh => $schema->storage->dbh);
    my $model = $intro->model;

To introspect a database other than the connection's own:

    my $intro = DBIO::ClickHouse::Introspect->new(dbh => $dbh, database => 'analytics');

Each model section is fetched by a per-section reader under the C<Introspect/>
subdirectory (L<DBIO::ClickHouse::Introspect::Tables>,
L<DBIO::ClickHouse::Introspect::Columns>,
L<DBIO::ClickHouse::Introspect::Indexes>), matching the family layout mandated
by core ADR 0018. The shared type parser lives in
L<DBIO::ClickHouse::Introspect::Util>.

=head2 Why C<system.*> and not C<information_schema>

ClickHouse ships C<information_schema> views for MySQL-client compatibility,
and this driver talks the MySQL wire protocol -- so reaching for them would be
the obvious move. It is the wrong one. C<information_schema> has no column for
the table engine, the sorting key or the partition key, and it flattens
ClickHouse's type strings into MySQL-ish approximations. Those are precisely
the things a ClickHouse table cannot be recreated or compared without. The
authoritative catalog is the C<system> database, and that is what this reads.

=head2 Model shape

    {
        tables                => { $name  => { ... } },
        columns               => { $table => [ { ... }, ... ] },
        indexes               => { },                 # always empty, see below
        data_skipping_indexes => { $table => { $name => { ... } } },
        foreign_keys          => { },                 # always empty, see below
    }

C<indexes> and C<foreign_keys> are present but always empty. They are kept so
that anything walking the canonical model of L<DBIO::Introspect::Base> finds
the sections it expects instead of autovivifying them; they are empty because
ClickHouse has neither B-tree indexes nor unique constraints nor foreign keys
(C<docs/adr/0004-no-foreign-keys.md>). ClickHouse's data-skipping indexes are
a different thing entirely and live in their own section --
L<DBIO::ClickHouse::Introspect::Indexes> explains why conflating them would be
actively harmful.

=head2 Round-trip fidelity

Type normalization is the exact inverse of L<DBIO::ClickHouse::DDL>'s type
map, so a table this driver deployed introspects back to the metadata it was
deployed from. The cases where that cannot hold -- C<String> being the target
of the whole string family, and explicitly numbered enums -- are enumerated in
L<DBIO::ClickHouse::Introspect::Util/Round-trip fidelity>. The diff layer must
know about them or it will report phantom changes.

Table comments and column comments are read here but are B<not> emitted by
L<DBIO::ClickHouse::DDL>, so they are a one-way street: introspection sees
them, a redeploy drops them. Core's C<changed_column_fields> does not compare
comments, so this does not produce a phantom diff today.

=head1 ATTRIBUTES

=head2 database

Database name to introspect. When undef (the default) all queries are scoped
to C<currentDatabase()>, i.e. the C<database=> component of the DSN.

=head1 METHODS

=head2 table_columns_info

Hashref C<{ col_name => { data_type, size, is_nullable, default_value,
is_auto_increment, extra } }>, with the native ClickHouse type of each column
parsed back into portable DBIO metadata by
L<DBIO::ClickHouse::Introspect::Util/normalize_type>.

C<extra> carries the flags that have no portable column-info home and that the
DDL layer reads back: C<low_cardinality>, C<unsigned>, C<fixed_string>,
C<list> (enum members), C<timezone>, plus C<default_kind> /
C<default_expression> for non-C<DEFAULT> defaults.

C<is_nullable> comes from the type string and nothing else.
L<DBIO::Introspect::Base> additionally folds C<is_pk> into it, for models whose
engine reports the C<NOT NULL> attribute separately from the key constraint;
this override does not, because ClickHouse spells nullability in the type and
the fold could only ever contradict it. See the comment on the assignment.

=head2 table_uniq_info

Always an empty arrayref.

ClickHouse has no unique constraints and no unique indexes. The MergeTree
sorting key is not unique either -- it is a sort order, and inserting the same
key twice stores it twice. Reporting anything here would make a generated
schema claim a uniqueness the database does not enforce, which DBIO would then
act on in C<find> and C<update_or_create>.

=head2 table_fk_info

Always an empty arrayref. ClickHouse has no foreign keys at all -- not even a
parsed-and-ignored syntax. See C<docs/adr/0004-no-foreign-keys.md>.

=head2 table_comment

The C<COMMENT> of the table, or C<undef>.

=head2 column_comment

The C<COMMENT> of one column, or C<undef>.

=head2 view_definition

SQL text of the view's C<SELECT>, or C<undef>.

ClickHouse has no C<information_schema.views.view_definition> worth reading
(it is empty on most versions), so the definition is recovered from
C<system.tables.create_table_query> by stripping the leading
C<CREATE [MATERIALIZED] VIEW ... AS>. Fetched lazily, and only for views.

=head2 result_class_extra_statements

Emits one C<< [ clickhouse_table => \%options ] >> statement per table, so a
schema regenerated by L<DBIO::Generate> carries the engine and the MergeTree
keys it needs to be redeployable. The shape is
L<DBIO::ClickHouse::Result>'s C<clickhouse_table>; key entries that are bare
column names come back as strings and expressions as SCALAR refs, which is
what that method accepts.

Views get nothing -- they have no engine options to restate.

C<primary_key> is emitted only when it actually differs from C<order_by>:
ClickHouse fills the primary key in from the sorting key when it was not
declared separately, and restating it would make every table look like it
declared a redundant prefix. C<settings> is not emitted either, because
C<engine_full> always reports the server's own defaults (C<index_granularity =
8192> and friends) and pinning those into a generated schema would freeze a
server default into user code.

=head1 NORMALIZED CONTRACT

These methods implement the generation contract defined in
L<DBIO::Introspect::Base>. C<table_keys>, C<table_columns>, C<table_pk_info>
and C<table_is_view> are inherited unchanged -- the model follows the
canonical shape, and the per-section readers already resolved
ClickHouse's peculiarities (the MergeTree key standing in for a primary key,
the engine name standing in for a table type). The methods below are
overridden because ClickHouse genuinely differs.

=head1 SEE ALSO

=over 4

=item * L<DBIO::ClickHouse::DDL> - the forward direction this module inverts

=item * L<DBIO::ClickHouse::Introspect::Util> - the type parser and its round-trip caveats

=item * L<DBIO::Introspect::Base> - the contract implemented here

=back

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
