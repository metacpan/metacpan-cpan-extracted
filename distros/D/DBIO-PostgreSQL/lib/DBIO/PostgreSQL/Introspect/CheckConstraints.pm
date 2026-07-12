package DBIO::PostgreSQL::Introspect::CheckConstraints;
# ABSTRACT: Introspect PostgreSQL CHECK constraints

use strict;
use warnings;

use DBIO::PostgreSQL::Introspect ();



sub fetch {
  my ($class, $dbh, $filter) = @_;

  my $sql = q{
    SELECT
      sn.nspname AS schema_name,
      cl.relname AS table_name,
      con.conname AS constraint_name,
      pg_catalog.pg_get_constraintdef(con.oid) AS definition,
      a.attname AS column_name,
      k.n AS key_seq
    FROM pg_catalog.pg_constraint con
    JOIN pg_catalog.pg_class cl ON cl.oid = con.conrelid
    JOIN pg_catalog.pg_namespace sn ON sn.oid = cl.relnamespace
    LEFT JOIN LATERAL unnest(con.conkey) WITH ORDINALITY AS k(attnum, n) ON true
    LEFT JOIN pg_catalog.pg_attribute a
      ON a.attrelid = con.conrelid AND a.attnum = k.attnum
    WHERE con.contype = 'c'
      AND NOT con.conislocal = false
  };
  $sql .= DBIO::PostgreSQL::Introspect->system_schema_filter('sn');

  my @bind;
  if ($filter && @$filter) {
    $sql .= ' AND sn.nspname = ANY($1)';
    push @bind, $filter;
  }

  $sql .= q{
    ORDER BY sn.nspname, cl.relname, con.conname, k.n
  };

  my $sth = $dbh->prepare($sql);
  $sth->execute(@bind);

  my %checks;
  while (my $row = $sth->fetchrow_hashref) {
    my $table_key = DBIO::PostgreSQL::Introspect->qualified_key($row);
    my $entry = $checks{$table_key}{ $row->{constraint_name} } //= {
      constraint_name => $row->{constraint_name},
      definition      => $row->{definition},
      columns         => [],
    };
    push @{ $entry->{columns} }, $row->{column_name} if defined $row->{column_name};
  }

  return \%checks;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Introspect::CheckConstraints - Introspect PostgreSQL CHECK constraints

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

Fetches CHECK constraint metadata from C<pg_catalog.pg_constraint> where
C<contype = 'c'>.

=head1 METHODS

=head2 fetch

    my $checks = DBIO::PostgreSQL::Introspect::CheckConstraints->fetch($dbh, $filter);

Returns a hashref keyed by C<schema.table>. Each value is a hashref keyed by
constraint name. Each entry has: C<constraint_name>, C<definition> (the CHECK
expression from C<pg_get_constraintdef>), C<columns> (ArrayRef of column names
the constraint references, may be empty for table-level checks).

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
