package TestDBIO::Extension::Age;
# ABSTRACT: AGE-like mock extension: claims graph schemas, activates ag_catalog

use strict;
use warnings;

use base 'DBIO::Extension';

sub extension_interface { 1 }
sub name   { 'age' }
sub driver { 'TestDBIO::Extension::Deploy' }

# Offline: the "database handle" of the fixture is a plain hash.
sub inspect {
  my ($class, $ctx) = @_;
  return { graphs => [ map { { %$_ } } @{ $ctx->{dbh}{graphs} || [] } ] };
}

sub claims {
  my ($class, $model, $ctx) = @_;
  return [ map { [ schema => $_->{namespace} ] }
    @{ ($ctx->{self}{state} || {})->{graphs} || [] } ];
}

sub activation { { load => 'age', search_path => ['ag_catalog'] } }

sub storage_layer { 'TestDBIO::Extension::Age::Storage' }

1;
