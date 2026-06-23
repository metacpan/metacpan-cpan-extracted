package DBIO::DB2::Introspect;
# ABSTRACT: Introspect a DB2 database via SYSCAT + information_schema

use strict;
use warnings;

use base 'DBIO::Introspect::Base';

use DBIO::DB2::Introspect::Tables;
use DBIO::DB2::Introspect::Columns;
use DBIO::DB2::Introspect::Indexes;
use DBIO::DB2::Introspect::ForeignKeys;


sub schema { $_[0]->{schema} // 'USER' }


sub _build_model {
  my ($self) = @_;
  my $dbh    = $self->dbh;
  my $schema = $self->schema;

  my $tables  = DBIO::DB2::Introspect::Tables->fetch($dbh, $schema);
  my $columns = DBIO::DB2::Introspect::Columns->fetch($dbh, $schema, $tables);
  my $indexes = DBIO::DB2::Introspect::Indexes->fetch($dbh, $schema, $tables);
  my $fks     = DBIO::DB2::Introspect::ForeignKeys->fetch($dbh, $schema, $tables);

  return {
    tables       => $tables,
    columns      => $columns,
    indexes      => $indexes,
    foreign_keys => $fks,
  };
}


sub table_fk_info {
  my ($self, $table_key) = @_;

  return [
    map {
      {
        constraint_name  => $_->{constraint_name},
        local_columns    => [ @{ $_->{from_columns} || [] } ],
        remote_columns   => [ @{ $_->{to_columns}   || [] } ],
        remote_schema    => $_->{to_schema},
        remote_table     => $_->{to_table},
        attrs            => {
          on_delete => $_->{on_delete},
          on_update => $_->{on_update},
        },
      }
    } @{ $self->model->{foreign_keys}{$table_key} || [] }
  ];
}


sub table_is_view {
  my ($self, $table_key) = @_;
  my $table = $self->model->{tables}{$table_key} || {};
  return ($table->{kind} || '') eq 'view' ? 1 : 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DB2::Introspect - Introspect a DB2 database via SYSCAT + information_schema

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

C<DBIO::DB2::Introspect> reads the live state of a DB2 database via
C<SYSCAT> and C<information_schema>, returning a unified model hashref.
It is the source side of the test-deploy-and-compare strategy used by
L<DBIO::DB2::Deploy>.

    my $intro = DBIO::DB2::Introspect->new(dbh => $dbh);
    my $model = $intro->model;

Model shape mirrors L<DBIO::DuckDB::Introspect>:

    {
        tables       => { $name => { ... } },
        columns      => { $table => [ { ... }, ... ] },
        indexes      => { $table => { $name => { ... } } },
        foreign_keys => { $table => [ { ... }, ... ] },
    }

=head1 ATTRIBUTES

=head2 schema

DB2 schema to introspect. Defaults to C<USER> (current user's schema).

=head1 METHODS

=head2 table_fk_info

=head2 table_is_view

=head1 NORMALIZED CONTRACT

The L<DBIO::Introspect::Base> contract used by L<DBIO::Generate> is satisfied
by the base-class defaults: the native model built by C<_build_model> already
uses the canonical shape (bare table-name keys; C<columns> with
C<column_name>/C<data_type>/C<size>/C<not_null>/C<default_value>/C<is_pk>/
C<pk_position>/C<is_auto_increment>; C<indexes> with C<origin> marking the PK
index; C<tables> with C<kind>). So C<table_keys>, C<table_columns>,
C<table_columns_info>, C<table_pk_info>, C<table_uniq_info> and C<table_is_view>
are inherited unchanged.

Only C<table_fk_info> is overridden: DB2 carries the constraint name and the
referenced schema, which the generic default drops.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
