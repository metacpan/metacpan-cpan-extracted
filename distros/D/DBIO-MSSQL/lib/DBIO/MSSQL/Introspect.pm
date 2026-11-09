package DBIO::MSSQL::Introspect;
# ABSTRACT: Introspect a Microsoft SQL Server database via information_schema

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Introspect::Base';


use DBIO::MSSQL::Introspect::Tables;
use DBIO::MSSQL::Introspect::Columns;
use DBIO::MSSQL::Introspect::Indexes;
use DBIO::MSSQL::Introspect::ForeignKeys;
use DBIO::MSSQL::Introspect::Views;

sub schema { $_[0]->{schema} // 'dbo' }


sub schemas { $_[0]->{schemas} // [] }

sub _build_model {
  my ($self) = @_;
  my $dbh    = $self->dbh;
  my $base   = $self->schema;

  my %model = (tables => {}, columns => {}, indexes => {}, foreign_keys => {}, schemas => {});
  my %seen;
  for my $schema (grep { !$seen{$_}++ } $base, @{ $self->schemas }) {
    my $key = $schema eq $base ? sub { $_[0] } : sub { "$schema.$_[0]" };

    my ($exists) = $dbh->selectrow_array(
      'SELECT COUNT(*) FROM sys.schemas WHERE name = ?', undef, $schema);
    next unless $exists;
    $model{schemas}{$schema} = { schema_name => $schema };

    my $tables  = DBIO::MSSQL::Introspect::Tables->fetch($dbh, $schema);
    my $columns = DBIO::MSSQL::Introspect::Columns->fetch($dbh, $schema, $tables);
    my $indexes = DBIO::MSSQL::Introspect::Indexes->fetch($dbh, $schema, $tables);
    my $fks     = DBIO::MSSQL::Introspect::ForeignKeys->fetch($dbh, $schema, $tables);

    # a view carries its stored text (karr k82)
    my $defs = DBIO::MSSQL::Introspect::Views->fetch($dbh, $schema);
    for my $name (grep { $tables->{$_}{kind} eq 'view' } keys %$defs) {
      $tables->{$name}{definition} = $defs->{$name};
    }
    # the views a view reads, as model keys (dbo bare, the others schema.name)
    my $deps = DBIO::MSSQL::Introspect::Views->dependencies($dbh, $schema);
    for my $name (grep { $tables->{$_} && $tables->{$_}{kind} eq 'view' } keys %$deps) {
      $tables->{$name}{depends_on} = [ map {
        $_->[0] eq $base ? $_->[1] : "$_->[0].$_->[1]"
      } @{ $deps->{$name} } ];
    }

    for my $t (keys %$tables) {
      $model{tables}{ $key->($t) } = { %{ $tables->{$t} }, table_name => $key->($t) };
    }
    $model{columns}{ $key->($_) } = $columns->{$_} for keys %$columns;
    $model{indexes}{ $key->($_) } = $indexes->{$_} for keys %$indexes;
    for my $t (keys %$fks) {
      $model{foreign_keys}{ $key->($t) } = [ map {
        +{ %$_,
           from_table => $key->($_->{from_table}),
           to_table   => ($_->{to_schema} eq $base ? $_->{to_table} : "$_->{to_schema}.$_->{to_table}") }
      } @{ $fks->{$t} } ];
    }
  }

  $model{collation} = $self->_fetch_collation($dbh);
  return \%model;
}

sub _fetch_collation {
  my ($self, $dbh) = @_;
  my ($name, $style) = $dbh->selectrow_array(q{
    SELECT CAST(DATABASEPROPERTYEX(DB_NAME(), 'Collation') AS nvarchar(128)),
           CAST(COLLATIONPROPERTY(
             CAST(DATABASEPROPERTYEX(DB_NAME(), 'Collation') AS sysname),
             'ComparisonStyle') AS int)
  });
  return { name => $name, case_sensitive => (($style // 0) & 1) ? 0 : 1 };
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MSSQL::Introspect - Introspect a Microsoft SQL Server database via information_schema

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

C<DBIO::MSSQL::Introspect> reads the live state of a Microsoft SQL Server
database via the standard SQL C<INFORMATION_SCHEMA> views. It is the
source side of the test-deploy-and-compare strategy used by
L<DBIO::MSSQL::Deploy>.

    my $intro = DBIO::MSSQL::Introspect->new(dbh => $dbh);
    my $model = $intro->model;

Model shape mirrors L<DBIO::SQLite::Introspect>:

    {
        tables       => { $name => { ... } },   # a view: kind => 'view', definition
        columns      => { $table => [ { ... }, ... ] },
        indexes      => { $table => { $name => { ... } } },
        foreign_keys => { $table => [ { ... }, ... ] },
        collation    => { name => '...', case_sensitive => 0|1 },
        schemas      => { $schema => { schema_name => $schema } },
    }

A table of the schema L</schema> (C<dbo>) is keyed by its bare name; the
tables of the other schemas asked for with L</schemas> are keyed
C<schema.table>. C<schemas> lists the schemas asked for that exist in the
database.

C<collation> is the collation of the database the handle is connected to: the
one that decides whether C<Foo> and C<foo> are the same name for a table,
column, index or constraint. C<case_sensitive> is read from the
C<ComparisonStyle> of the collation (bit 1 set: case is ignored), so a binary
collation (C<..._BIN2>) is case-sensitive too. L<DBIO::MSSQL::Diff> compares
names by the collation of its source model.

=head1 ATTRIBUTES

=head2 schema

Schema name to introspect. Defaults to C<dbo>. Its tables are keyed by their
bare name in the model.

=head2 schemas

    my $intro = DBIO::MSSQL::Introspect->new(dbh => $dbh, schemas => ['other']);

More schemas to introspect besides L</schema>, default none. Their
tables, columns, indexes and foreign keys are keyed C<schema.table> in the
model, and a foreign key that references a table of another schema than
L</schema> says C<schema.table> in C<to_table> (C<to_schema> carries the schema
on its own). A schema that does not exist is not an error: it has no tables and
is not listed in the C<schemas> section.
L<DBIO::MSSQL::Deploy> passes the schemas the classes name.

=head1 NORMALIZED INTROSPECTION CONTRACT

The seven L<DBIO::Introspect::Base> contract methods (C<table_keys>,
C<table_columns>, C<table_columns_info>, C<table_pk_info>,
C<table_uniq_info>, C<table_fk_info>, C<table_is_view>) are B<inherited
unchanged> from the base: they are pure reads over the canonical
L<model|DBIO::Introspect::Base/model> this class builds, so this
introspector serves as a high-fidelity source
for L<DBIO::Generate> with no driver-specific override. Two model details
make the defaults correct here: L<DBIO::MSSQL::Introspect::Columns> emits
the canonical C<is_auto_increment> flag (alongside the MSSQL-native
C<is_identity>), and L<DBIO::MSSQL::Introspect::Indexes> already excludes
primary-key indexes, so C<table_uniq_info> never double-reports the PK.

=head1 SEE ALSO

=pod

=over

=item * L<DBIO::MSSQL::Deploy> - uses this class for test-deploy-and-compare

=item * L<DBIO::MSSQL::Diff> - compares two models produced by this class

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
