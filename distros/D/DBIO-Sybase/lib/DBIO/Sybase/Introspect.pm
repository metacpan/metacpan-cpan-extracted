package DBIO::Sybase::Introspect;
# ABSTRACT: Introspect a Sybase ASE database via its system catalog

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Introspect::Base';


use DBIO::Sybase::Introspect::Tables;
use DBIO::Sybase::Introspect::Columns;
use DBIO::Sybase::Introspect::Indexes;
use DBIO::Sybase::Introspect::ForeignKeys;
use DBIO::Sybase::Introspect::Views;

sub schema { $_[0]->{schema} // 'dbo' }


sub _build_model {
  my ($self) = @_;
  my $dbh    = $self->dbh;
  my $schema = $self->schema;

  my $tables  = DBIO::Sybase::Introspect::Tables->fetch($dbh, $schema);
  my $columns = DBIO::Sybase::Introspect::Columns->fetch($dbh, $schema, $tables);
  my $indexes = DBIO::Sybase::Introspect::Indexes->fetch($dbh, $schema, $tables);
  my $fks_raw = DBIO::Sybase::Introspect::ForeignKeys->fetch($dbh, $schema, $tables);
  my $views   = DBIO::Sybase::Introspect::Views->fetch($dbh, $schema, $tables);

  # Group the per-column FK rows into one entry per constraint, in declared
  # order (composite FKs must keep local<->remote column pairing). The
  # order-preserving grouping lives in DBIO::Introspect::Base.
  my $foreign_keys = $self->_group_fks_by_constraint($fks_raw);

  # The primary key is the index Indexes marked origin => 'pk' (sysindexes
  # status & 2048); its key order is the pk_position.
  $self->_mark_pk_columns($indexes, $columns);

  return {
    tables       => $tables,
    columns      => $columns,
    indexes      => $indexes,
    foreign_keys => $foreign_keys,
    views        => $views,
  };
}

sub _group_fks_by_constraint {
  my ($self, $fks_raw) = @_;
  my $out = {};
  for my $table (sort keys %$fks_raw) {
    my $rows    = $fks_raw->{$table} // [];
    my $ordered = $self->_aggregate_by_ordered($rows, 'constraint_name');
    my @entries;
    for my $pair (@$ordered) {
      my ($cn, $rows) = @$pair;
      push @entries, {
        constraint_name => $cn,
        from_columns => [ map { $_->{column_name}     } @$rows ],
        to_table     => $rows->[0]{ref_table_name},
        to_columns   => [ map { $_->{ref_column_name} } @$rows ],
        on_update    => $rows->[0]{update_rule},
        on_delete    => $rows->[0]{delete_rule},
      };
    }
    $out->{$table} = \@entries;
  }
  return $out;
}

sub _mark_pk_columns {
  my ($self, $indexes, $columns) = @_;
  for my $table (sort keys %$indexes) {
    my ($pk) = grep { ($_->{origin} // '') eq 'pk' } values %{ $indexes->{$table} };
    next unless $pk;
    my %pos;
    @pos{ @{ $pk->{columns} } } = (1 .. @{ $pk->{columns} });
    for my $col (@{ $columns->{$table} // [] }) {
      my $p = $pos{ $col->{column_name} } or next;
      $col->{is_pk}       = 1;
      $col->{pk_position} = $p;
    }
  }
}


sub view_definition {
  my ($self, $key) = @_;
  return undef unless $self->table_is_view($key);

  my $chunks = $self->dbh->selectcol_arrayref(q{
    SELECT m.text
    FROM syscomments m
    JOIN sysobjects  o ON o.id = m.id
    JOIN sysusers    u ON u.uid = o.uid
    WHERE u.name = ? AND o.name = ? AND o.type = 'V'
    ORDER BY m.colid2, m.colid
  }, undef, $self->schema, $key);
  return undef unless $chunks && @$chunks;
  return DBIO::Sybase::Introspect::Views::strip_head(
    join '', map { $_ // '' } @$chunks);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Sybase::Introspect - Introspect a Sybase ASE database via its system catalog

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

C<DBIO::Sybase::Introspect> reads the live state of a Sybase ASE database
from its system catalog -- C<sysobjects>, C<syscolumns>, C<systypes>,
C<syscomments>, C<sysindexes> (with C<index_col()>) and C<sysreferences>.
SAP ASE ships B<no> C<INFORMATION_SCHEMA> views (that is SQL Server and the
ANSI catalog); a query against them is Msg 208 on ASE 16.0. It is
both sides of the test-deploy-and-compare strategy used by
L<DBIO::Sybase::Deploy>: the live database and the temporary one the desired
schema is deployed into are read by this class alike, so every value it
reports must come out the same for two deployments of the same DDL.

    my $intro = DBIO::Sybase::Introspect->new(dbh => $dbh);
    my $model = $intro->model;

Model shape (canonical — single-schema, un-qualified keys):

    {
        tables       => { $name => { ... } },
        columns      => { $table => [ { ... }, ... ] },
        indexes      => { $table => { $name => { ... } } },
        foreign_keys => { $table => [ { constraint_name, from_columns,
                                        to_table, to_columns,
                                        on_update, on_delete } ] },
        views        => { $name => { view_name, definition, depends_on } },
    }

A view is listed in C<tables> (C<kind> C<view>) with its columns, and in
C<views> with the text after C<AS> and the views it reads from
(L<DBIO::Sybase::Introspect::Views>).

The FK rows in C<foreign_keys> are pre-grouped per constraint (one entry
per FK, with C<from_columns> / C<to_columns> as arrayrefs) so the default
L<DBIO::Introspect::Base/table_fk_info> contract method applies unchanged.
Each entry also carries C<constraint_name> -- the live, server-assigned
name -- so the diff layer can C<DROP>/C<ALTER> a foreign key by its real
name instead of a generated one (see ADR 0021; C<constraint_name> is FK
metadata, not a compared attribute).

=head1 ATTRIBUTES

=head2 schema

Schema name to introspect. Defaults to C<dbo>.

=head1 METHODS

=head2 view_definition

SQL text of the view definition (the C<SELECT>), or C<undef>. Read from
C<syscomments>, where ASE keeps the whole C<CREATE VIEW> statement split over
rows of at most 255 characters; the rows are joined and the
C<CREATE VIEW ... AS> head is stripped.

=head1 SEE ALSO

=pod

=over

=item * L<DBIO::Sybase::Deploy> - uses this class for test-deploy-and-compare

=item * L<DBIO::Sybase::Diff> - compares two models produced by this class

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
