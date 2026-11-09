package DBIO::PostgreSQL::Introspect::Extensions;
# ABSTRACT: Introspect PostgreSQL extensions

use strict;
use warnings;

our $VERSION = '0.900004';

use DBIO::PostgreSQL::Introspect ();



sub fetch {
  my ($class, $dbh) = @_;

  my $sql = q{
    SELECT
      e.extname AS extension_name,
      e.extversion AS version,
      n.nspname AS schema_name,
      e.extrelocatable AS relocatable,
      ARRAY(
        SELECT r.extname::text
        FROM pg_catalog.pg_depend d
        JOIN pg_catalog.pg_extension r ON r.oid = d.refobjid
        WHERE d.classid = 'pg_catalog.pg_extension'::pg_catalog.regclass
          AND d.objid = e.oid
          AND d.refclassid = 'pg_catalog.pg_extension'::pg_catalog.regclass
          AND d.deptype = 'n'
          AND r.extname != 'plpgsql'
        ORDER BY r.extname
      ) AS requires
    FROM pg_catalog.pg_extension e
    JOIN pg_catalog.pg_namespace n ON n.oid = e.extnamespace
    WHERE e.extname != 'plpgsql'
    ORDER BY e.extname
  };

  my $sth = $dbh->prepare($sql);
  $sth->execute;

  my %extensions;
  while (my $row = $sth->fetchrow_hashref) {
    $extensions{ $row->{extension_name} } = {
      extension_name => $row->{extension_name},
      version        => $row->{version},
      schema_name    => $row->{schema_name},
      relocatable    => $row->{relocatable} ? 1 : 0,
      requires       => DBIO::PostgreSQL::Introspect->normalize_array($row->{requires}) // [],
    };
  }

  return \%extensions;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Introspect::Extensions - Introspect PostgreSQL extensions

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Fetches installed PostgreSQL extension metadata from
C<pg_catalog.pg_extension>. The built-in C<plpgsql> extension is excluded
since it is always present.

=head1 METHODS

=head2 fetch

    my $extensions = DBIO::PostgreSQL::Introspect::Extensions->fetch($dbh);

Returns a hashref keyed by extension name. Each entry has:
C<extension_name>, C<version>, C<schema_name> (the schema the extension is
installed in -- the one it depends on, so the schema is not dropped
while the extension is in it), C<relocatable>, and C<requires>: the names of the
installed extensions this one depends on, by name, an empty ArrayRef when
there are none. That is what the catalog records (C<pg_depend>, extension on
extension, deptype C<n>) -- the C<requires> of the control file as it was
resolved at C<CREATE EXTENSION>. L<DBIO::PostgreSQL::Diff::Extension> creates
and drops extensions in the order it gives. C<plpgsql>, not in the model, is
not listed.

No schema filter is accepted — extensions are database-level objects.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
