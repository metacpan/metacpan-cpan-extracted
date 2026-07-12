package DBIO::DuckDB::Introspect;
# ABSTRACT: Introspect a DuckDB database via information_schema + duckdb_* views

use strict;
use warnings;

use base 'DBIO::Introspect::Base';

use DBIO::DuckDB::Introspect::Tables;
use DBIO::DuckDB::Introspect::Columns;
use DBIO::DuckDB::Introspect::Indexes;
use DBIO::DuckDB::Introspect::ForeignKeys;


sub schema  { $_[0]->{schema}  // 'main' }
sub catalog { $_[0]->{catalog} }



sub _build_model {
  my ($self) = @_;
  my $dbh     = $self->dbh;
  my $schema  = $self->schema;
  my $catalog = $self->catalog;

  my $tables  = DBIO::DuckDB::Introspect::Tables->fetch($dbh, $schema, $catalog);
  my $columns = DBIO::DuckDB::Introspect::Columns->fetch($dbh, $schema, $tables, $catalog);
  my $indexes = DBIO::DuckDB::Introspect::Indexes->fetch($dbh, $schema, $tables, $catalog);
  my $fks     = DBIO::DuckDB::Introspect::ForeignKeys->fetch($dbh, $schema, $tables, $catalog);

  return {
    tables       => $tables,
    columns      => $columns,
    indexes      => $indexes,
    foreign_keys => $fks,
  };
}


sub table_columns_info {
  my ($self, $key) = @_;

  my %pk = map { $_ => 1 } @{ $self->table_pk_info($key) };
  my %info;

  for my $col (@{ $self->model->{columns}{$key} || [] }) {
    my $name = $col->{column_name};
    my $i = { is_nullable => $col->{not_null} ? 0 : 1 };
    $self->_normalize_data_type($i, $col->{data_type});
    $self->_normalize_default_value($i, $col->{default_value}, $pk{$name});
    $info{$name} = $i;
  }

  return \%info;
}

sub _normalize_data_type {
  my ($self, $info, $raw) = @_;
  my $type = defined $raw ? $raw : '';
  $type =~ s/^\s+//;
  $type =~ s/\s+\z//;

  # DECIMAL(p,s) / NUMERIC(p,s)
  if ($type =~ /^(decimal|numeric)\s*\(\s*(\d+)\s*,\s*(\d+)\s*\)\z/i) {
    $info->{data_type} = lc $1;
    $info->{size} = [ 0 + $2, 0 + $3 ];
    return;
  }

  # VARCHAR(n) / CHAR(n) / DECIMAL(p) etc.
  if ($type =~ /^([A-Za-z][\w ]*?)\s*\(\s*(\d+)\s*\)\z/) {
    $info->{data_type} = lc $1;
    $info->{size} = 0 + $2;
    return;
  }

  $info->{data_type} = lc $type;
}

sub _normalize_default_value {
  my ($self, $info, $default, $is_pk) = @_;
  return unless defined $default;

  my $value = $default;
  $value =~ s/^\s+//;
  $value =~ s/\s+\z//;

  # Auto-increment: DEFAULT nextval('seq')
  if ($value =~ /\bnextval\(\s*'?"?([^'")]+)"?'?\s*\)/i) {
    $info->{is_auto_increment} = 1;
    $info->{sequence} = $1;
    $info->{retrieve_on_insert} = 1 if $is_pk;
    return;
  }

  # String literal, optionally CAST(...)
  if ($value =~ /^CAST\(\s*'(.*?)'\s+AS\s+[\w ]+\)\z/is
   || $value =~ /^'(.*?)'(?:::[\w ]+)?\z/s) {
    $info->{default_value} = $1;
  }
  # Bare number
  elsif ($value =~ /^-?\d+(?:\.\d+)?\z/) {
    $info->{default_value} = $value;
  }
  # NULL
  elsif ($value =~ /^NULL\z/i) {
    my $null = 'null';
    $info->{default_value} = \$null;
  }
  # Function / keyword literal (CURRENT_TIMESTAMP, now(), ...)
  else {
    my $literal = lc($value) eq 'now()' ? 'current_timestamp' : $value;
    $info->{default_value} = \$literal;
  }

  $info->{retrieve_on_insert} = 1 if $is_pk && !$info->{is_auto_increment};
}


sub table_uniq_info {
  my ($self, $key) = @_;
  my $indexes = $self->model->{indexes}{$key} || {};
  my @uniq;
  for my $name (sort keys %$indexes) {
    my $idx = $indexes->{$name};
    next unless $idx->{is_unique};
    next if $idx->{partial};
    next unless @{ $idx->{columns} || [] };
    push @uniq, [ $name => $idx->{columns} ];
  }
  return \@uniq;
}


sub view_definition {
  my ($self, $key) = @_;
  return undef unless $self->table_is_view($key);

  my $sql = q{
    SELECT view_definition
    FROM information_schema.views
    WHERE table_schema = ? AND table_name = ?
  };
  my @bind = ($self->schema, $key);
  if (defined $self->catalog) {
    $sql .= q{ AND table_catalog = ?};
    push @bind, $self->catalog;
  }

  my ($def) = $self->dbh->selectrow_array($sql, undef, @bind);
  return undef unless defined $def;
  $def =~ s/^\s+//;
  $def =~ s/\s+\z//;
  $def =~ s/\s*;\s*\z//;
  return $def;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DuckDB::Introspect - Introspect a DuckDB database via information_schema + duckdb_* views

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

C<DBIO::DuckDB::Introspect> reads the live state of a DuckDB database
via the standard SQL C<information_schema> views and DuckDB's system
views (C<duckdb_tables()>, C<duckdb_columns()>, C<duckdb_indexes()>,
C<duckdb_constraints()>). It is the source side of the
test-deploy-and-compare strategy used by L<DBIO::DuckDB::Deploy>.

    my $intro = DBIO::DuckDB::Introspect->new(dbh => $dbh);
    my $model = $intro->model;

With a locally-attached file or DuckLake catalog pass C<catalog>:

    my $intro = DBIO::DuckDB::Introspect->new(dbh => $dbh, catalog => 'mycat');
    my $model = $intro->model;

Model shape mirrors L<DBIO::SQLite::Introspect>:

    {
        tables       => { $name => { ... } },
        columns      => { $table => [ { ... }, ... ] },
        indexes      => { $table => { $name => { ... } } },
        foreign_keys => { $table => [ { ... }, ... ] },
    }

B<Quack RPC catalogs are opaque:> C<information_schema> and
C<duckdb_indexes()> return no rows for tables in a remote Quack-attached
catalog. Do not pass C<catalog> for a Quack remote. To inspect a remote
table's columns from the client side, use C<PRAGMA table_info('remote.tablename')>
directly on a known table.

Only the default C<main> schema is introspected unless C<schema> is overridden.

=head1 ATTRIBUTES

=head2 schema

Schema name to introspect. Defaults to C<main>.

=head2 catalog

Optional catalog name. When set, restricts introspection to the named
catalog (e.g. a locally-attached file DB or DuckLake volume). Adds
C<AND table_catalog = ?> / C<AND database_name = ?> filters to all
queries. When undef (the default) the existing schema-only queries run
unchanged.

B<Do not use with Quack RPC catalogs> -- remote quack catalogs are
opaque to C<information_schema> and DuckDB system views.

=head1 METHODS

=head2 table_columns_info

Hashref C<{ col_name => { data_type, size, is_nullable, default_value,
is_auto_increment, sequence, ... } }>.

=head2 table_uniq_info

List of C<[ $index_name, \@col_names ]> pairs for non-partial unique
indexes. PK-backed indexes are already excluded from the model.

=head2 view_definition

SQL text of the view definition, or C<undef>. Fetched lazily from
C<information_schema.views> on demand.

=head1 NORMALIZED CONTRACT

These methods implement the generation contract defined in
L<DBIO::Introspect::Base>. The canonical-model defaults in
L<DBIO::Introspect::Base> (C<table_keys>, C<table_columns>,
C<table_pk_info>, C<table_fk_info>, C<table_is_view>) are inherited
unchanged -- the DuckDB native model follows the canonical shape. Only
C<table_columns_info> (DuckDB-specific C<nextval()> auto-increment and
type-size normalization), C<table_uniq_info> (partial-unique exclusion),
and C<view_definition> (lazy C<information_schema.views> lookup) are
overridden below. Table keys are plain table names (only the C<main>
schema is introspected).

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
