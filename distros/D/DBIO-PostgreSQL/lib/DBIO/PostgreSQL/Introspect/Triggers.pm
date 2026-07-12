package DBIO::PostgreSQL::Introspect::Triggers;
# ABSTRACT: Introspect PostgreSQL triggers

use strict;
use warnings;

use DBIO::PostgreSQL::Introspect ();



sub fetch {
  my ($class, $dbh, $filter) = @_;

  my $sql = q{
    SELECT
      n.nspname AS schema_name,
      c.relname AS table_name,
      t.tgname AS trigger_name,
      pg_catalog.pg_get_triggerdef(t.oid) AS definition,
      CASE
        WHEN t.tgtype & 2 = 2 THEN 'BEFORE'
        WHEN t.tgtype & 64 = 64 THEN 'INSTEAD OF'
        ELSE 'AFTER'
      END AS timing,
      CASE
        WHEN t.tgtype & 4 = 4 THEN 'INSERT'
        WHEN t.tgtype & 8 = 8 THEN 'DELETE'
        WHEN t.tgtype & 16 = 16 THEN 'UPDATE'
        WHEN t.tgtype & 32 = 32 THEN 'TRUNCATE'
      END AS event,
      CASE WHEN t.tgtype & 1 = 1 THEN 'ROW' ELSE 'STATEMENT' END AS orientation,
      t.tgenabled AS enabled
    FROM pg_catalog.pg_trigger t
    JOIN pg_catalog.pg_class c ON c.oid = t.tgrelid
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    WHERE NOT t.tgisinternal
  };
  $sql .= DBIO::PostgreSQL::Introspect->system_schema_filter('n');

  my @bind;
  if ($filter && @$filter) {
    $sql .= ' AND n.nspname = ANY($1)';
    push @bind, $filter;
  }

  $sql .= ' ORDER BY n.nspname, c.relname, t.tgname';

  my $sth = $dbh->prepare($sql);
  $sth->execute(@bind);

  my %triggers;
  while (my $row = $sth->fetchrow_hashref) {
    my $table_key = DBIO::PostgreSQL::Introspect->qualified_key($row);
    $triggers{$table_key}{ $row->{trigger_name} } = {
      trigger_name => $row->{trigger_name},
      definition   => $row->{definition},
      timing       => $row->{timing},
      event        => $row->{event},
      orientation  => $row->{orientation},
      enabled      => $row->{enabled},
    };
  }

  return \%triggers;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Introspect::Triggers - Introspect PostgreSQL triggers

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

Fetches user-defined trigger metadata from C<pg_catalog.pg_trigger>. Internal
(constraint) triggers are excluded. Timing (C<BEFORE>/C<AFTER>/C<INSTEAD OF>),
event (C<INSERT>/C<UPDATE>/C<DELETE>/C<TRUNCATE>), and orientation
(C<ROW>/C<STATEMENT>) are decoded from the C<tgtype> bitmask.

=head1 METHODS

=head2 fetch

    my $triggers = DBIO::PostgreSQL::Introspect::Triggers->fetch($dbh, $filter);

Returns a hashref keyed by C<schema.table>. Each value is a hashref keyed by
trigger name. Each trigger entry has: C<trigger_name>, C<definition> (from
C<pg_get_triggerdef>), C<timing>, C<event>, C<orientation>, C<enabled>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
