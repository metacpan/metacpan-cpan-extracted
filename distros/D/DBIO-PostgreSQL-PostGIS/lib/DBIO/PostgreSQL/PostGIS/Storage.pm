package DBIO::PostgreSQL::PostGIS::Storage;
# ABSTRACT: Storage class with PostGIS spatial extensions

use strict;
use warnings;

use base 'DBIO::PostgreSQL::Storage';


sub ensure_postgis {
  my $self = shift;
  $self->dbh_do(sub {
    my (undef, $dbh) = @_;
    $dbh->do('CREATE EXTENSION IF NOT EXISTS postgis');
  });
}


sub postgis_version {
  my $self = shift;
  return $self->dbh_do(sub {
    my (undef, $dbh) = @_;
    my ($v) = eval { $dbh->selectrow_array('SELECT PostGIS_Full_Version()') };
    return $v;
  });
}

sub dbio_deploy_class { 'DBIO::PostgreSQL::PostGIS::Deploy' }


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::PostGIS::Storage - Storage class with PostGIS spatial extensions

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

Extends L<DBIO::PostgreSQL::Storage> with PostGIS-aware introspection,
spatial data type recognition, and helper methods for common spatial
operations.

=head1 METHODS

=head2 ensure_postgis

  $storage->ensure_postgis;

Issues C<CREATE EXTENSION IF NOT EXISTS postgis> against the connected
database. Idempotent.

=head2 postgis_version

  my $v = $storage->postgis_version;

Returns the PostGIS extension version string from C<PostGIS_Full_Version()>,
or undef if the extension is not installed.

=head2 dbio_deploy_class

Returns C<DBIO::PostgreSQL::PostGIS::Deploy> to activate PostGIS-aware
deploy when C<< $schema->deploy >> is called on a PostGIS-enabled schema.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
