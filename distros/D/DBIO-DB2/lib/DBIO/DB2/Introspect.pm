package DBIO::DB2::Introspect;
# ABSTRACT: Introspect a DB2 database via SYSCAT

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Introspect::Base';

use DBIO::DB2::Introspect::Tables;
use DBIO::DB2::Introspect::Columns;
use DBIO::DB2::Introspect::Indexes;
use DBIO::DB2::Introspect::ForeignKeys;
use DBIO::DB2::Introspect::UniqueConstraints;


sub schema { $_[0]->{schema} // 'USER' }


sub _build_model {
  my ($self) = @_;
  my $dbh    = $self->dbh;
  my $schema = $self->schema;

  my $tables  = DBIO::DB2::Introspect::Tables->fetch($dbh, $schema);
  my $columns = DBIO::DB2::Introspect::Columns->fetch($dbh, $schema, $tables);
  my $indexes = DBIO::DB2::Introspect::Indexes->fetch($dbh, $schema, $tables);
  my $fks     = DBIO::DB2::Introspect::ForeignKeys->fetch($dbh, $schema, $tables);
  my $ucs     = DBIO::DB2::Introspect::UniqueConstraints->fetch($dbh, $schema, $tables);

  return {
    tables             => $tables,
    columns            => $columns,
    indexes            => $indexes,
    foreign_keys       => $fks,
    unique_constraints => $ucs,
  };
}


sub table_uniq_info {
  my ($self, $key) = @_;
  my $model   = $self->model;
  my $indexes = $model->{indexes}{$key} || {};
  return [
    map { [ @$_ ] } @{ $model->{unique_constraints}{$key} || [] },
    map { [ $_ => $indexes->{$_}{columns} ] }
      grep { $indexes->{$_}{is_unique} && ($indexes->{$_}{origin} || '') ne 'pk' }
      sort keys %$indexes
  ];
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

DBIO::DB2::Introspect - Introspect a DB2 database via SYSCAT

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

C<DBIO::DB2::Introspect> reads the live state of a DB2 database via
C<SYSCAT>, returning a unified model hashref.
It is the source side of the test-deploy-and-compare strategy used by
L<DBIO::DB2::Deploy>.

    my $intro = DBIO::DB2::Introspect->new(dbh => $dbh);
    my $model = $intro->model;

Model shape mirrors L<DBIO::DuckDB::Introspect>:

    {
        tables             => { $name => { ... } },   # a view also has view_definition
        columns            => { $table => [ { ... }, ... ] },
        indexes            => { $table => { $name => { ... } } },   # incl. the PK index, origin 'pk'
        foreign_keys       => { $table => [ { ... }, ... ] },
        unique_constraints => { $table => [ [ $name, \@columns ], ... ] },
    }

C<unique_constraints> is the optional section of the
L<DBIO::Introspect::Base> contract (ADR 0009). The index Db2 keeps behind a
C<UNIQUE> constraint is part of the constraint and not in C<indexes>.

=head1 ATTRIBUTES

=head2 schema

DB2 schema to introspect. Defaults to C<USER> (current user's schema).

=head1 METHODS

=head2 table_uniq_info

The C<UNIQUE> constraints, then the unique indexes made with
C<CREATE UNIQUE INDEX> (the index behind the primary key is in the model with
C<< origin => 'pk' >>, and left out here, ADR 0011).

=head2 table_fk_info

=head2 table_is_view

=head1 NORMALIZED CONTRACT

The L<DBIO::Introspect::Base> contract used by L<DBIO::Generate> is satisfied
by the base-class defaults: the native model built by C<_build_model> already
uses the canonical shape (bare table-name keys; C<columns> with
C<column_name>/C<data_type>/C<size>/C<not_null>/C<default_value>/C<is_pk>/
C<pk_position>/C<is_auto_increment> in the normalized form
L<DBIO::DB2::Introspect::Columns> describes -- lower-case C<data_type>, the
declared C<size> (absent for a type Db2 declares without one), the C<default_value>
as a value or a SCALAR reference for an expression -- plus the internal
C<catalog_type>/C<catalog_size>/C<catalog_default> that only the diff reads
(ADR 0013); C<indexes> with C<origin> marking the PK
index; C<tables> with C<kind>). So C<table_keys>, C<table_columns>,
C<table_columns_info>, C<table_pk_info>, C<table_uniq_info> and C<table_is_view>
are inherited unchanged.

C<table_fk_info> and C<table_uniq_info> are overridden: DB2 carries the
constraint name and the referenced schema, which the generic default drops; and
the base takes the C<unique_constraints> section as the whole answer, which here
would lose the unique indexes of C<db2_indexes>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
