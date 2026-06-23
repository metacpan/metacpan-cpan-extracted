package DBIO::PostgreSQL::Introspect::Extensions;
# ABSTRACT: Introspect PostgreSQL extensions

use strict;
use warnings;



sub fetch {
  my ($class, $dbh) = @_;

  my $sql = q{
    SELECT
      e.extname AS extension_name,
      e.extversion AS version,
      n.nspname AS schema_name,
      e.extrelocatable AS relocatable
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

version 0.900000

=head1 DESCRIPTION

Fetches installed PostgreSQL extension metadata from
C<pg_catalog.pg_extension>. The built-in C<plpgsql> extension is excluded
since it is always present.

=head1 METHODS

=head2 fetch

    my $extensions = DBIO::PostgreSQL::Introspect::Extensions->fetch($dbh);

Returns a hashref keyed by extension name. Each entry has:
C<extension_name>, C<version>, C<schema_name> (the schema the extension's
objects live in), C<relocatable>.

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
