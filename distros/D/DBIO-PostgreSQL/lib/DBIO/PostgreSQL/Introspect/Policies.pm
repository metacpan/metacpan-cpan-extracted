package DBIO::PostgreSQL::Introspect::Policies;
# ABSTRACT: Introspect PostgreSQL Row Level Security policies

use strict;
use warnings;

use DBIO::PostgreSQL::Introspect ();



sub fetch {
  my ($class, $dbh, $filter) = @_;

  my $sql = q{
    SELECT
      n.nspname AS schema_name,
      c.relname AS table_name,
      p.polname AS policy_name,
      CASE p.polcmd
        WHEN 'r' THEN 'SELECT'
        WHEN 'a' THEN 'INSERT'
        WHEN 'w' THEN 'UPDATE'
        WHEN 'd' THEN 'DELETE'
        WHEN '*' THEN 'ALL'
      END AS command,
      p.polpermissive AS permissive,
      pg_catalog.pg_get_expr(p.polqual, p.polrelid) AS using_expr,
      pg_catalog.pg_get_expr(p.polwithcheck, p.polrelid) AS check_expr,
      array_agg(r.rolname) FILTER (WHERE r.rolname IS NOT NULL) AS roles
    FROM pg_catalog.pg_policy p
    JOIN pg_catalog.pg_class c ON c.oid = p.polrelid
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    LEFT JOIN pg_catalog.pg_roles r ON r.oid = ANY(p.polroles)
    WHERE 1=1
  };
  $sql .= DBIO::PostgreSQL::Introspect->system_schema_filter('n');

  my @bind;
  if ($filter && @$filter) {
    $sql .= ' AND n.nspname = ANY($1)';
    push @bind, $filter;
  }

  $sql .= q{
    GROUP BY n.nspname, c.relname, p.polname, p.polcmd,
             p.polpermissive, p.polqual, p.polwithcheck, p.polrelid
    ORDER BY n.nspname, c.relname, p.polname
  };

  my $sth = $dbh->prepare($sql);
  $sth->execute(@bind);

  my %policies;
  while (my $row = $sth->fetchrow_hashref) {
    my $table_key = DBIO::PostgreSQL::Introspect->qualified_key($row);
    $policies{$table_key}{ $row->{policy_name} } = {
      policy_name => $row->{policy_name},
      command     => $row->{command},
      permissive  => $row->{permissive} ? 1 : 0,
      using_expr  => $row->{using_expr},
      check_expr  => $row->{check_expr},
      roles       => $row->{roles},
    };
  }

  return \%policies;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Introspect::Policies - Introspect PostgreSQL Row Level Security policies

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

Fetches Row Level Security policy metadata from C<pg_catalog.pg_policy>.
Policy command types and USING/WITH CHECK expressions are decoded from
PostgreSQL's internal representation.

=head1 METHODS

=head2 fetch

    my $policies = DBIO::PostgreSQL::Introspect::Policies->fetch($dbh, $filter);

Returns a hashref keyed by C<schema.table>. Each value is a hashref keyed by
policy name. Each policy entry has: C<policy_name>, C<command> (C<SELECT>,
C<INSERT>, C<UPDATE>, C<DELETE>, or C<ALL>), C<permissive>, C<using_expr>,
C<check_expr>, C<roles> (ArrayRef of role names, or undef for all roles).

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
