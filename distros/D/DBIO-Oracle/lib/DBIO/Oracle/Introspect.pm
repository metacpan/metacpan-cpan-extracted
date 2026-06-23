package DBIO::Oracle::Introspect;
# ABSTRACT: Introspect an Oracle database via all_* views

use strict;
use warnings;

use base 'DBIO::Introspect::Base';


use DBIO::Oracle::Introspect::Tables ();
use DBIO::Oracle::Introspect::Columns ();
use DBIO::Oracle::Introspect::Indexes ();
use DBIO::Oracle::Introspect::ForeignKeys ();
use DBIO::Oracle::Introspect::Keys ();


sub schema { $_[0]->{schema} //= $_[0]->_default_schema }

sub _default_schema {
  my ($self) = @_;
  my ($schema) = $self->dbh->selectrow_array('SELECT USER FROM DUAL');
  return $schema;
}

sub _build_model {
  my ($self) = @_;
  my $dbh    = $self->dbh;
  my $schema = $self->schema;

  my $tables  = DBIO::Oracle::Introspect::Tables->fetch($dbh, $schema);
  my $columns = DBIO::Oracle::Introspect::Columns->fetch($dbh, $schema, $tables);
  my $indexes = DBIO::Oracle::Introspect::Indexes->fetch($dbh, $schema, $tables);
  my $fks     = DBIO::Oracle::Introspect::ForeignKeys->fetch($dbh, $schema, $tables);
  my $keys    = DBIO::Oracle::Introspect::Keys->fetch($dbh, $schema, $tables);

  return {
    tables             => $tables,
    columns            => $columns,
    indexes            => $indexes,
    foreign_keys       => $fks,
    primary_keys       => $keys->{primary},
    unique_constraints => $keys->{unique},
  };
}


sub table_columns_info {
  my ($self, $key) = @_;
  my $cols = $self->model->{columns}{$key} // [];
  my %info;
  for my $col (@$cols) {
    my %col_info = (
      data_type   => $col->{data_type},
      is_nullable => $col->{not_null} ? 0 : 1,
    );
    $col_info{size}              = $col->{size}          if defined $col->{size};
    $col_info{default_value}     = $col->{default_value} if exists $col->{default_value};
    $col_info{is_auto_increment} = 1                     if $col->{is_auto_increment};
    $col_info{sequence}          = $col->{sequence}      if defined $col->{sequence};
    $info{ $col->{column_name} } = \%col_info;
  }
  return \%info;
}


sub table_pk_info {
  my ($self, $key) = @_;
  return $self->model->{primary_keys}{$key} // [];
}


sub table_fk_info {
  my ($self, $key) = @_;
  my $fks = $self->model->{foreign_keys}{$key} // [];
  return [
    map {
      {
        local_columns  => $_->{from_columns},
        remote_table   => $_->{to_table},
        remote_schema  => undef,
        remote_columns => $_->{to_columns},
        attrs          => {
          on_delete     => $_->{on_delete},
          on_update     => $_->{on_update},
          is_deferrable => $_->{is_deferrable} ? 1 : 0,
        },
      }
    } @$fks
  ];
}


sub view_definition {
  my ($self, $key) = @_;
  return undef unless $self->table_is_view($key);

  my $dbh = $self->dbh;
  local $dbh->{LongReadLen} = 1_000_000;
  local $dbh->{LongTruncOk} = 0;

  my ($text) = $dbh->selectrow_array(
    'SELECT text FROM all_views WHERE owner = ? AND view_name = ?',
    undef, $self->schema, $key,
  );
  return undef unless defined $text;
  $text =~ s/^\s+//;
  $text =~ s/\s+\z//;
  $text =~ s/\s*;\s*\z//;
  return $text;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Oracle::Introspect - Introspect an Oracle database via all_* views

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

C<DBIO::Oracle::Introspect> reads the live state of an Oracle database
via the C<all_*> data dictionary views (C<all_tables>, C<all_tab_columns>,
C<all_indexes>, C<all_constraints>, etc.). It is the source side of the
test-deploy-and-compare strategy used by L<DBIO::Oracle::Deploy>.

    my $intro = DBIO::Oracle::Introspect->new(
        dbh => $dbh,
        schema => 'MYUSER',
    );
    my $model = $intro->model;

Model shape:

    {
        tables       => { $name => { ... } },
        columns      => { $table => [ { ... }, ... ] },
        indexes      => { $table => { $name => { ... } } },
        foreign_keys => { $table => [ { ... }, ... ] },
        primary_keys => { $table => [ $col, ... ] },
        unique_constraints => { $table => [ [ $name => \@cols ], ... ] },
    }

The Oracle introspection is built on the C<all_*> data dictionary views,
providing sequence detection via trigger inspection, LOB type handling,
and other Oracle-specific behaviors.

=head1 ATTRIBUTES

=head2 schema

Schema (user) name to introspect. Defaults to the current connected user
(via C<SELECT USER FROM DUAL>).

=head1 METHODS

=head2 table_columns_info

    my \%info = %{ $intro->table_columns_info($key) };

Hashref of normalized per-column metadata. The Oracle override adds the
C<sequence> field (populated from BEFORE INSERT trigger inspection) on
top of the canonical C<data_type> / C<size> / C<is_nullable> /
C<default_value> / C<is_auto_increment> fields.

=head2 table_pk_info

    my \@pk_cols = @{ $intro->table_pk_info($key) };

Ordered list of primary key column names. The Oracle introspector
populates PKs in a separate C<primary_keys> section (keyed by table),
not as C<is_pk> flags on the columns -- so the canonical default, which
walks the C<columns> section, would return an empty list. This override
reads the dedicated section.

=head2 table_fk_info

    my \@fks = @{ $intro->table_fk_info($key) };

Each FK is a hashref in the normalized contract shape. The Oracle
override adds C<is_deferrable> to C<attrs> -- the canonical
implementation drops it, and the Oracle storage layer (C<ALTER SESSION
SET CONSTRAINTS = DEFERRED>) needs to know whether a constraint is
DEFERRABLE.

=head2 view_definition

SQL text of the view definition, or C<undef>. Read from C<all_views> (a
C<LONG> column, so C<LongReadLen> is raised for the fetch).

=head1 NORMALIZED CONTRACT

The canonical L<DBIO::Introspect::Base> contract methods
(C<table_keys>, C<table_columns>, C<table_uniq_info>, C<table_is_view>)
are inherited unchanged -- the Oracle model uses bare table names as keys
and a C<unique_constraints> section, both of which match the canonical
shape. The four methods below override the base to surface Oracle-specific
data that the canonical model would drop.

=seealso

=over 4

=item * L<DBIO::Oracle::Deploy> - uses this class to compare current and desired state

=item * L<DBIO::Oracle::Diff> - compares two models produced by this class

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
