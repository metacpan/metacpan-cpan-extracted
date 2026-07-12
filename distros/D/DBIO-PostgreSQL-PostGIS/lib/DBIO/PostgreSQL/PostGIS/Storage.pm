package DBIO::PostgreSQL::PostGIS::Storage;
# ABSTRACT: Storage class with PostGIS spatial extensions

use strict;
use warnings;


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


sub _ensure_postgis_extension {
  my $self = shift;
  my $installed = $self->dbh_do(sub {
    my (undef, $dbh) = @_;
    my ($row) = $dbh->selectrow_array(
      "SELECT 1 FROM pg_extension WHERE extname = 'postgis'",
    );
    return defined $row ? 1 : 0;
  });
  return if $installed;
  my $dbname = $self->dbh_do(sub {
    my (undef, $dbh) = @_;
    my ($n) = $dbh->selectrow_array('SELECT current_database()');
    return $n;
  });
  $dbname = defined $dbname ? "'$dbname'" : '(unknown)';
  $self->throw_exception(
    "PostGIS extension is not installed on database $dbname "
      . '(required by DBIO::PostgreSQL::PostGIS)'
  );
}

sub dbio_deploy_class { 'DBIO::PostgreSQL::PostGIS::Deploy' }


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::PostGIS::Storage - Storage class with PostGIS spatial extensions

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

A storage B<layer> that adds PostGIS-aware helper methods (extension
ensure/probe, version, deploy-class selection) to a PostgreSQL storage. It is
B<not> a storage subclass: it is a plain method package composed over the
resolved driver storage at connection time (see L<DBIO::Storage::Composed>).
L<DBIO::PostgreSQL::PostGIS> registers it via
L<DBIO::Schema/register_storage_layer>, so on C<< $schema->connect >> the live
storage isa B<both> this layer and L<DBIO::PostgreSQL::Storage>, and its methods
below are callable on that composed storage.

=head2 Layer rules

Per the storage-layer composition model (DBIO core, storage-layer composition):
this package does B<not> C<use base> a driver storage, defines no constructor,
and calls only the documented public storage surface (C<dbh_do>,
C<throw_exception>) -- which resolves through the composed MRO to the driver
base at runtime. New methods here (C<ensure_postgis>, C<postgis_version>,
C<_ensure_postgis_extension>) do not shadow any base method; C<dbio_deploy_class>
below is a deliberate override of the base hook.

=head2 dbio_deploy_class is a single-owner base-hook override

L</dbio_deploy_class> overrides the base storage's deploy-class hook to route
C<< $schema->deploy >> through the PostGIS-aware deploy class. Under the core
composition collision rule, exactly B<one> composed layer may own a given
method: if a second deploy-hooking extension (e.g. another spatial/graph layer
that also defines its own C<dbio_deploy_class>) is registered alongside this
one, composition B<croaks at compose time> naming C<dbio_deploy_class> and every
defining package. That is fail-loud by design -- the deploy class cannot be
silently decided by registration order. Two deploy-extending extensions on one
schema is a new core requirement (deploy-hook chaining), not a workaround here.

=head2 No async layer

PostGIS ships B<no> C<::Async> sibling: its storage surface (extension ensure,
version, deploy class) is synchronous, and the spatial codecs / ResultSet
helpers are not storage-async-level. Core composition B<skips silently> any
registered layer that has no C<::Async> mirror, so under any async connection
mode (C<< { async => ... } >>) the composed async backend simply carries no
PostGIS async layer, and CRUD on geometry columns flows through the transport
unchanged. If async deploy or codec hooks are ever needed, that is a separate
ticket.

=head1 METHODS

=head2 ensure_postgis

  $storage->ensure_postgis;

Issues C<CREATE EXTENSION IF NOT EXISTS postgis> against the connected
database. Idempotent.

=head2 postgis_version

  my $v = $storage->postgis_version;

Returns the PostGIS extension version string from C<PostGIS_Full_Version()>,
or undef if the extension is not installed.

=head2 _ensure_postgis_extension

  $storage->_ensure_postgis_extension;

Cheap fail-fast check that the C<postgis> extension is installed on the
connected database. Throws a L<DBIO::Exception> with a message naming
the missing extension and the database when the extension is not
present. A no-op when the extension is installed.

Intended to be wrapped around first-use storage operations by callers
that require PostGIS (deploy, schema load, geometry inflation). The
core driver does not call this automatically so that storage
construction against a non-PostGIS database remains possible for
introspection and other PostGIS-agnostic tasks.

=head2 dbio_deploy_class

Returns C<DBIO::PostgreSQL::PostGIS::Deploy> to activate PostGIS-aware
deploy when C<< $schema->deploy >> is called on a PostGIS-enabled schema.
This overrides the base storage's deploy-class hook; as a single-owner base
override it composes cleanly, but a second layer that also defines its own
C<dbio_deploy_class> makes composition croak (see L</dbio_deploy_class is a
single-owner base-hook override>).

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
