package DBIO::PostgreSQL::Introspect::OutsideReaders;
# ABSTRACT: Introspect the views outside the schema filter that read columns inside it

use strict;
use warnings;

our $VERSION = '0.900004';

use DBIO::PostgreSQL::Introspect ();



sub fetch {
  my ($class, $dbh, $filter) = @_;
  return {} unless $filter && @$filter;

  my $sql = q{
    SELECT DISTINCT
      n.nspname AS schema_name,
      c.relname AS table_name,
      c.relkind AS kind,
      rn.nspname AS ref_schema,
      r.relname AS ref_name,
      a.attname AS ref_column
    FROM pg_catalog.pg_rewrite rw
    JOIN pg_catalog.pg_class c ON c.oid = rw.ev_class
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    JOIN pg_catalog.pg_depend d
      ON d.classid = 'pg_catalog.pg_rewrite'::pg_catalog.regclass
     AND d.objid = rw.oid
     AND d.refclassid = 'pg_catalog.pg_class'::pg_catalog.regclass
     AND d.refobjsubid > 0
    JOIN pg_catalog.pg_class r ON r.oid = d.refobjid AND r.oid <> c.oid
    JOIN pg_catalog.pg_namespace rn ON rn.oid = r.relnamespace
    JOIN pg_catalog.pg_attribute a ON a.attrelid = d.refobjid AND a.attnum = d.refobjsubid
    WHERE c.relkind IN ('v', 'm')
      AND rn.nspname = ANY($1)
      AND NOT (n.nspname = ANY($1))
  };
  $sql .= DBIO::PostgreSQL::Introspect->system_schema_filter('n');
  $sql .= DBIO::PostgreSQL::Introspect->extension_member_filter('pg_class', 'c.oid');
  $sql .= ' ORDER BY n.nspname, c.relname, rn.nspname, r.relname, a.attname';

  my $rows = $dbh->selectall_arrayref($sql, { Slice => {} }, $filter);

  my %readers;
  for my $row (@$rows) {
    my $key  = DBIO::PostgreSQL::Introspect->qualified_key($row);
    my $read = DBIO::PostgreSQL::Introspect->qualified_key(@{$row}{qw( ref_schema ref_name )});
    my $view = $readers{$key} //= {
      schema_name => $row->{schema_name},
      table_name  => $row->{table_name},
      kind        => $row->{kind},
      depends_on_columns => {},
    };
    push @{ $view->{depends_on_columns}{$read} }, $row->{ref_column};
  }

  return \%readers;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Introspect::OutsideReaders - Introspect the views outside the schema filter that read columns inside it

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

The model is bounded by the schema filter (C<pg_schemas>): a view in a schema
outside it is not in the C<tables> section, and the diff neither creates, drops
nor re-creates it. It still holds the columns it reads, and PostgreSQL does not
alter the type of a column a view uses. This section names such views, so that
L<DBIO::PostgreSQL::Diff::Column> can refuse the type change by name instead of
leaving it to the server.

Without a schema filter every schema is in the model and the section is empty.

=head1 METHODS

=head2 fetch

    my $readers = DBIO::PostgreSQL::Introspect::OutsideReaders->fetch($dbh, $filter);

Returns a hashref keyed by C<schema.view>, for each view or materialized view
in a schema that is not in C<$filter> and reads a column of a relation that is.
Each value has C<schema_name>, C<table_name>, C<kind> (C<v> or C<m>) and
C<depends_on_columns>, a HashRef from the key of a relation I<in> the filter to
an ArrayRef of column names, sorted, the same shape as the one of
L<DBIO::PostgreSQL::Introspect::Tables>. Only the views that read such a column
are in it, and only their direct readers: a view that stands on one of them
fails with it, and is named by the server when it is dropped. System schemas
and what an extension owns are left out.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
