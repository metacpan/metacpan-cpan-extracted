package DBIO::PostgreSQL::Introspect::Functions;
# ABSTRACT: Introspect PostgreSQL functions

use strict;
use warnings;

use DBIO::PostgreSQL::Introspect ();



sub fetch {
  my ($class, $dbh, $filter) = @_;

  my $sql = q{
    SELECT
      n.nspname AS schema_name,
      p.proname AS function_name,
      p.oid AS function_oid,
      pg_catalog.pg_get_function_identity_arguments(p.oid) AS identity_args,
      pg_catalog.pg_get_functiondef(p.oid) AS definition,
      l.lanname AS language,
      p.provolatile AS volatility,
      p.proisstrict AS is_strict,
      p.prosecdef AS security_definer,
      pg_catalog.format_type(p.prorettype, NULL) AS return_type
    FROM pg_catalog.pg_proc p
    JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
    JOIN pg_catalog.pg_language l ON l.oid = p.prolang
    WHERE 1=1
      AND p.prokind IN ('f', 'p')
  };
  $sql .= DBIO::PostgreSQL::Introspect->system_schema_filter('n');

  my @bind;
  if ($filter && @$filter) {
    $sql .= ' AND n.nspname = ANY($1)';
    push @bind, $filter;
  }

  $sql .= ' ORDER BY n.nspname, p.proname';

  my $sth = $dbh->prepare($sql);
  $sth->execute(@bind);

  my %functions;
  while (my $row = $sth->fetchrow_hashref) {
    my $key = "$row->{schema_name}.$row->{function_name}($row->{identity_args})";
    $functions{$key} = {
      schema_name      => $row->{schema_name},
      function_name    => $row->{function_name},
      identity_args    => $row->{identity_args},
      definition       => $row->{definition},
      language         => $row->{language},
      volatility       => $row->{volatility},
      is_strict        => $row->{is_strict} ? 1 : 0,
      security_definer => $row->{security_definer} ? 1 : 0,
      return_type      => $row->{return_type},
    };
  }

  return \%functions;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Introspect::Functions - Introspect PostgreSQL functions

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

Fetches function and procedure metadata from C<pg_catalog.pg_proc>. The full
function definition is retrieved via C<pg_get_functiondef>. System functions
(in C<pg_*> and C<information_schema> schemas) are excluded.

=head1 METHODS

=head2 fetch

    my $functions = DBIO::PostgreSQL::Introspect::Functions->fetch($dbh, $filter);

Returns a hashref keyed by C<schema.function_name(identity_args)>. Each entry
has: C<schema_name>, C<function_name>, C<identity_args>, C<definition> (full
source from C<pg_get_functiondef>), C<language>, C<volatility> (C<i>/C<s>/C<v>),
C<is_strict>, C<security_definer>, C<return_type>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
