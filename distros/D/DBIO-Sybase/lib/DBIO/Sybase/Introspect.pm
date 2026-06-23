package DBIO::Sybase::Introspect;
# ABSTRACT: Introspect a Sybase ASE database via information_schema

use strict;
use warnings;

use base 'DBIO::Introspect::Base';


use DBIO::Sybase::Introspect::Tables;
use DBIO::Sybase::Introspect::Columns;
use DBIO::Sybase::Introspect::Indexes;
use DBIO::Sybase::Introspect::ForeignKeys;

sub schema { $_[0]->{schema} // 'dbo' }


sub _build_model {
  my ($self) = @_;
  my $dbh    = $self->dbh;
  my $schema = $self->schema;

  my $tables  = DBIO::Sybase::Introspect::Tables->fetch($dbh, $schema);
  my $columns = DBIO::Sybase::Introspect::Columns->fetch($dbh, $schema, $tables);
  my $indexes = DBIO::Sybase::Introspect::Indexes->fetch($dbh, $schema, $tables);
  my $fks_raw = DBIO::Sybase::Introspect::ForeignKeys->fetch($dbh, $schema, $tables);

  # Group the per-column FK rows into one entry per constraint, in declared
  # order (composite FKs must keep local<->remote column pairing). The
  # order-preserving grouping lives in DBIO::Introspect::Base.
  my $foreign_keys = $self->_group_fks_by_constraint($fks_raw);

  # Mark indexes that back a primary key with origin => 'pk' so the inherited
  # table_uniq_info drops them. PK-backing indexes are matched by column set.
  $self->_mark_pk_index_origin($indexes, $columns);

  return {
    tables       => $tables,
    columns      => $columns,
    indexes      => $indexes,
    foreign_keys => $foreign_keys,
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

sub _mark_pk_index_origin {
  my ($self, $indexes, $columns) = @_;
  for my $table (sort keys %$indexes) {
    my $tbl_cols = $columns->{$table} // [];
    my @pk_cols  = sort map { $_->{column_name} }
      grep { $_->{is_pk} } @$tbl_cols;
    next unless @pk_cols;
    my $pk_sig = join "\0", @pk_cols;
    for my $name (sort keys %{ $indexes->{$table} }) {
      my $idx = $indexes->{$table}{$name};
      my @idx_cols = sort @{ $idx->{columns} // [] };
      next unless @idx_cols;
      next unless join("\0", @idx_cols) eq $pk_sig;
      $idx->{origin} = 'pk';
    }
  }
}


sub view_definition {
  my ($self, $key) = @_;
  return undef unless $self->table_is_view($key);

  my ($def) = $self->dbh->selectrow_array(
    q{SELECT view_definition FROM INFORMATION_SCHEMA.VIEWS
      WHERE table_schema = ? AND table_name = ?},
    undef, $self->schema, $key,
  );
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

DBIO::Sybase::Introspect - Introspect a Sybase ASE database via information_schema

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

C<DBIO::Sybase::Introspect> reads the live state of a Sybase ASE database
via the standard SQL C<INFORMATION_SCHEMA> views. It is the source side
of the test-deploy-and-compare strategy used by L<DBIO::Sybase::Deploy>.

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
    }

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

SQL text of the view definition, or C<undef>.

=seealso

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
