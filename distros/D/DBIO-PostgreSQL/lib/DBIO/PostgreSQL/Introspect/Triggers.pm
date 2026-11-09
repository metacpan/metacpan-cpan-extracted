package DBIO::PostgreSQL::Introspect::Triggers;
# ABSTRACT: Introspect PostgreSQL triggers

use strict;
use warnings;

our $VERSION = '0.900004';

use DBIO::PostgreSQL::Introspect ();
use DBIO::PostgreSQL::Util ();




sub execute_call {
  my ($class, $row) = @_;
  my $function = $row->{function_signature};
  return undef unless defined $function && $function =~ /\(\)\z/;
  substr($function, -2) = '';

  my @args;
  my $count = $row->{argument_count} // 0;
  if ($count > 0) {
    my $bytes = pack 'H*', $row->{arguments_hex} // '';
    @args = (split /\0/, $bytes, -1)[ 0 .. $count - 1 ];
    for my $arg (@args) {
      $arg //= '';
      utf8::decode($arg);
      $arg = DBIO::PostgreSQL::Util::quote_literal($arg);
    }
  }
  return $function . '(' . join(', ', @args) . ')';
}

sub fetch {
  my ($class, $dbh, $filter) = @_;

  my $sql = q{
    SELECT
      n.nspname AS schema_name,
      c.relname AS table_name,
      t.tgname AS trigger_name,
      pg_catalog.pg_get_triggerdef(t.oid) AS definition,
      t.tgfoid::pg_catalog.regprocedure::pg_catalog.text AS function_signature,
      t.tgnargs AS argument_count,
      pg_catalog.encode(t.tgargs, 'hex') AS arguments_hex,
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
      AND t.tgparentid = 0
  };
  $sql .= DBIO::PostgreSQL::Introspect->system_schema_filter('n');
  $sql .= DBIO::PostgreSQL::Introspect->extension_member_filter('pg_class', 'c.oid');

  my @bind;
  if ($filter && @$filter) {
    $sql .= ' AND n.nspname = ANY($1)';
    push @bind, $filter;
  }

  $sql .= ' ORDER BY n.nspname, c.relname, t.tgname';

  my $sth = $dbh->prepare($sql);
  $sth->execute(@bind);

  my $reads = DBIO::PostgreSQL::Introspect->column_reads(
    $dbh, $filter, 'pg_trigger', 'tgrelid', 'tgname',
    'NOT o.tgisinternal AND o.tgparentid = 0',
  );

  my %triggers;
  while (my $row = $sth->fetchrow_hashref) {
    my $table_key = DBIO::PostgreSQL::Introspect->qualified_key($row);
    $triggers{$table_key}{ $row->{trigger_name} } = {
      schema_name  => $row->{schema_name},
      table_name   => $row->{table_name},
      trigger_name => $row->{trigger_name},
      definition   => $row->{definition},
      execute      => $class->execute_call($row),
      timing       => $row->{timing},
      event        => $row->{event},
      orientation  => $row->{orientation},
      enabled      => $row->{enabled},
      depends_on_columns => $reads->{$table_key}{ $row->{trigger_name} } // {},
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

version 0.900004

=head1 DESCRIPTION

Fetches user-defined trigger metadata from C<pg_catalog.pg_trigger>. Internal
(constraint) triggers are excluded. Timing (C<BEFORE>/C<AFTER>/C<INSTEAD OF>),
event (C<INSERT>/C<UPDATE>/C<DELETE>/C<TRUNCATE>), and orientation
(C<ROW>/C<STATEMENT>) are decoded from the C<tgtype> bitmask.
A trigger on a partitioned table is carried down to every partition by the
server, as a copy with C<pg_trigger.tgparentid> set; the copy goes with the
parent's trigger and is left out of the model, a trigger a partition has by its
own declaration is in it.
Tables an installed extension owns are left out by
L<DBIO::PostgreSQL::Introspect::Tables>, and their triggers with them.

=head1 METHODS

=head2 fetch

    my $triggers = DBIO::PostgreSQL::Introspect::Triggers->fetch($dbh, $filter);

Returns a hashref keyed by C<schema.table>. Each value is a hashref keyed by
trigger name. Each trigger entry has: C<schema_name> and C<table_name> (the
table it is on, each name for itself -- the key cannot be taken apart again),
C<trigger_name>, C<definition> (from
C<pg_get_triggerdef>), C<timing>, C<event>, C<orientation>, C<enabled>,
C<depends_on_columns>.

C<depends_on_columns> is the columns the trigger is bound to: those of its
C<WHEN> condition and of C<UPDATE OF col, ...>, a HashRef from the key of a
relation to an ArrayRef of column names, sorted, from the C<pg_depend> rows of
the trigger (L<DBIO::PostgreSQL::Introspect/column_reads>). It is empty for a
trigger without either. What the trigger's function reads is not in it.
PostgreSQL does not alter the type of such a column (C<cannot alter type of a
column used in a trigger definition>); L<DBIO::PostgreSQL::Diff::Column> asks
it before it changes one.

=head2 execute_call

    my $call = DBIO::PostgreSQL::Introspect::Triggers->execute_call($row);

The function a trigger runs, written as the call of C<EXECUTE FUNCTION>:
C<name(arg, ...)>, each argument a string literal. It is built from the
catalog columns of the trigger -- the function from C<pg_trigger.tgfoid>
(C<regprocedure>, the name as the C<search_path> finds it) and the arguments
from C<pg_trigger.tgargs> -- and never read out of the text of
C<pg_get_triggerdef>. C<$row> has C<function_signature>, C<argument_count>
and C<arguments_hex> (C<tgargs> as hex). The result is the C<execute> key of
a trigger entry.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
