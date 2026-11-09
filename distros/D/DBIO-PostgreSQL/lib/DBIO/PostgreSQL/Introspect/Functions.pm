package DBIO::PostgreSQL::Introspect::Functions;
# ABSTRACT: Introspect PostgreSQL functions

use strict;
use warnings;

our $VERSION = '0.900004';

use DBIO::PostgreSQL::Introspect ();



sub fetch {
  my ($class, $dbh, $filter) = @_;

  my $sql = q{
    SELECT
      n.nspname AS schema_name,
      p.proname AS function_name,
      p.prokind AS kind,
      p.oid AS function_oid,
      pg_catalog.pg_get_function_identity_arguments(p.oid) AS identity_args,
      (SELECT COALESCE(pg_catalog.string_agg(pg_catalog.format_type(u.t, NULL), ',' ORDER BY u.ord), '')
         FROM pg_catalog.unnest(p.proargtypes::pg_catalog.oid[]) WITH ORDINALITY AS u(t, ord)) AS input_types,
      CASE WHEN p.prokind IN ('f', 'p')
           THEN pg_catalog.pg_get_functiondef(p.oid) END AS definition,
      CASE p.prokind
        WHEN 'a' THEN (
          SELECT pg_catalog.concat_ws('|',
            ag.aggkind, ag.aggnumdirectargs::text,
            ag.aggtransfn::pg_catalog.oid::pg_catalog.regprocedure::text,
            ag.aggfinalfn::pg_catalog.oid::pg_catalog.regprocedure::text,
            ag.aggcombinefn::pg_catalog.oid::pg_catalog.regprocedure::text,
            ag.aggserialfn::pg_catalog.oid::pg_catalog.regprocedure::text,
            ag.aggdeserialfn::pg_catalog.oid::pg_catalog.regprocedure::text,
            ag.aggmtransfn::pg_catalog.oid::pg_catalog.regprocedure::text,
            ag.aggminvtransfn::pg_catalog.oid::pg_catalog.regprocedure::text,
            ag.aggmfinalfn::pg_catalog.oid::pg_catalog.regprocedure::text,
            ag.aggfinalextra::text, ag.aggmfinalextra::text,
            ag.aggfinalmodify::text, ag.aggmfinalmodify::text,
            ag.aggsortop::pg_catalog.oid::pg_catalog.regoperator::text,
            pg_catalog.format_type(ag.aggtranstype, NULL),
            ag.aggtransspace::text,
            COALESCE(pg_catalog.format_type(NULLIF(ag.aggmtranstype, 0), NULL), ''),
            ag.aggmtransspace::text,
            COALESCE(ag.agginitval, '<null>'), COALESCE(ag.aggminitval, '<null>'),
            p.provolatile::text, p.proparallel::text, p.proisstrict::text,
            pg_catalog.format_type(p.prorettype, NULL))
          FROM pg_catalog.pg_aggregate ag WHERE ag.aggfnoid = p.oid)
        WHEN 'w' THEN pg_catalog.concat_ws('|',
          l.lanname, COALESCE(p.prosrc, ''), COALESCE(p.probin, ''),
          p.provolatile::text, p.proparallel::text, p.proisstrict::text,
          pg_catalog.format_type(p.prorettype, NULL))
      END AS fingerprint,
      l.lanname AS language,
      p.provolatile AS volatility,
      p.proisstrict AS is_strict,
      p.prosecdef AS security_definer,
      pg_catalog.format_type(p.prorettype, NULL) AS return_type
    FROM pg_catalog.pg_proc p
    JOIN pg_catalog.pg_namespace n ON n.oid = p.pronamespace
    JOIN pg_catalog.pg_language l ON l.oid = p.prolang
    WHERE 1=1
      AND p.prokind IN ('f', 'p', 'a', 'w')
  };
  $sql .= DBIO::PostgreSQL::Introspect->system_schema_filter('n');
  $sql .= DBIO::PostgreSQL::Introspect->extension_member_filter('pg_proc', 'p.oid');
  $sql .= DBIO::PostgreSQL::Introspect->internal_part_filter('pg_proc', 'p.oid');

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
      kind             => $row->{kind},
      identity_args    => $row->{identity_args},
      input_types      => $row->{input_types},
      definition       => $row->{definition},
      ( defined $row->{fingerprint} ? (fingerprint => $row->{fingerprint}) : () ),
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

version 0.900004

=head1 DESCRIPTION

Fetches function and procedure metadata from C<pg_catalog.pg_proc>. The full
function definition is retrieved via C<pg_get_functiondef>. System functions
(in C<pg_*> and C<information_schema> schemas) are excluded, and so are the
member functions of an installed extension (a C<pg_depend> row of deptype
C<e>): C<CREATE EXTENSION> / C<DROP EXTENSION> own them, so they are not the
schema's to create or drop one by one.

Left out as well are the functions PostgreSQL made as part of another object
(a C<pg_depend> row of deptype C<i>,
L<DBIO::PostgreSQL::Introspect/internal_part_filter>): the constructor
functions of a range type and of its multirange type. C<CREATE TYPE ... AS
RANGE> makes them and C<DROP TYPE> takes them; the type is in the model
(L<DBIO::PostgreSQL::Introspect::Types>), and they are part of it.

=head1 METHODS

=head2 fetch

    my $functions = DBIO::PostgreSQL::Introspect::Functions->fetch($dbh, $filter);

Returns a hashref keyed by C<schema.function_name(identity_args)>. Each entry
has: C<schema_name>, C<function_name>, C<identity_args>, C<definition> (full
source from C<pg_get_functiondef>), C<language>, C<volatility> (C<i>/C<s>/C<v>),
C<is_strict>, C<security_definer>, C<return_type>, C<kind> (C<pg_proc.prokind>:
C<f> function, C<p> procedure, C<a> aggregate, C<w> window function) and
C<input_types>, the types of the arguments the server files the routine by
(C<pg_proc.proargtypes>, comma separated, written like C<identity_args>): one
function or procedure per schema, name and C<input_types>, so a function and
a procedure with the same ones can not stand side by side whatever the names
and modes of their arguments (L<DBIO::PostgreSQL::Diff::Function/diff>).

An aggregate and a window function have no C<definition> (C<undef>):
C<pg_get_functiondef> raises an error for them. They carry a C<fingerprint>
instead, the text of the catalog rows that define them (C<pg_aggregate>; for
a window function the language, source and library), so that two models can be
told apart. The diff does not write one from it
(L<DBIO::PostgreSQL::Diff::Function/diff>).

C<identity_args>, C<return_type> and the head of C<definition> are written by
the server for the session that asks, without the schema of a type that
session's C<search_path> finds -- and C<identity_args> is part of the key. In
a model read with L<DBIO::PostgreSQL::Introspect/qualified_names> (the
default) every type outside C<pg_catalog> comes with its schema, in the key
too (C<app.label(s app.status)>); read without it the same function is filed
under two keys by two sessions with another C<search_path>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
