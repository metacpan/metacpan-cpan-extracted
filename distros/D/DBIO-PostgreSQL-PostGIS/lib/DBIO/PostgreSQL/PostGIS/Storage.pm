package DBIO::PostgreSQL::PostGIS::Storage;
# ABSTRACT: Storage class with PostGIS spatial extensions

use strict;
use warnings;

our $VERSION = '0.900004';

use DBIO::PostgreSQL::Util ();
use DBIO::PostgreSQL::DDL ();


sub ensure_postgis {
  my $self = shift;

  my $schema   = $self->schema;
  my $declared = $schema && $schema->can('pg_extension_schemas')
    ? $schema->pg_extension_schemas
    : {};
  my $into = $declared->{postgis};
  $into = $self->_postgis_control_schema // 'public' unless defined $into;
  my $namespace = $self->connection_schema;

  $self->throw_exception(sprintf
    'refusing to create the extension postgis in schema %s, the namespace '
    . 'this connection works in (connect key schema). An extension belongs '
    . 'to the database and is not installed into the namespace of one '
    . 'connection; name another schema for it, '
    . 'pg_extensions(postgis => { schema => ... }).',
    $into,
  ) if defined $namespace && $into eq $namespace;

  my $sql = 'CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA '
    . DBIO::PostgreSQL::Util::quote_ident($into);

  $self->dbh_do(sub {
    my (undef, $dbh) = @_;
    $dbh->do($sql);
  });
}

# The schema the control file of the server fixes for postgis (the rule of
# dbio-postgresql k141/k142, asked with the driver's own statement), or undef.
sub _postgis_control_schema {
  my $self = shift;
  my $rows = $self->dbh_do(sub {
    my (undef, $dbh) = @_;
    $dbh->selectall_arrayref(
      DBIO::PostgreSQL::DDL::control_schemas_sql('postgis'));
  }) // [];
  my ($row) = grep { $_->[0] eq 'postgis' } @$rows;
  return $row ? $row->[1] : undef;
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


sub async_layer_class {
  my ($class, $mode) = @_;
  return undef;   # stated: deliberately sync-only for every async mode (core k159, ADR 0032 addendum 2026-09-25)
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::PostGIS::Storage - Storage class with PostGIS spatial extensions

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

A storage B<layer> that adds PostGIS-aware helper methods (extension
ensure/probe, version) to a PostgreSQL storage. It is
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
C<throw_exception>, C<schema>, C<connection_schema>) -- which resolves through
the composed MRO to the driver base at runtime. New methods here
(C<ensure_postgis>, C<postgis_version>, C<_ensure_postgis_extension>) do not
shadow any base method. The layer does not define C<dbio_deploy_class>: that
hook has one owner, the driver storage (ADR 0066, section 4). The model rules of
PostGIS are in L<DBIO::PostgreSQL::PostGIS::Extension>; the driver registers
this layer for a declared C<postgis> (C<< storage_layer >> of that class).

=head2 No async layer

PostGIS ships B<no> C<::Async> sibling: its storage surface (extension ensure,
version) is synchronous, and the spatial codecs / ResultSet
helpers are not storage-async-level. The layer B<states> this through
L</async_layer_class>, which returns C<undef> for every async mode -- the
declared sync-only opt-out of the core async-mirror resolver (ADR 0032
addendum 2026-09-25). Core therefore neither probes nor loads a C<::Async>
sibling for it, so under any async connection mode (C<< { async => ... } >>)
the composed async backend carries no PostGIS async layer, and CRUD on
geometry columns flows through the transport unchanged. If async deploy or
codec hooks are ever needed, that is a separate ticket.

=head1 METHODS

=head2 ensure_postgis

  $storage->ensure_postgis;

Makes sure the C<postgis> extension is installed in the connected database:
C<CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA ...>. Idempotent.

The statement always names the schema. It is the one the schema class
declares for the extension,

  __PACKAGE__->pg_extensions(postgis => { schema => 'gis' });

(L<DBIO::PostgreSQL/pg_extension_schemas>); when it declares none, the schema
the control file of the server fixes for postgis (asked with
L<DBIO::PostgreSQL::DDL/control_schemas_sql>, only then); and C<public> when
that fixes none -- for a schema class without the L<DBIO::PostgreSQL>
component and a storage without a schema class as well. Where the extension goes therefore
does not depend on the C<search_path> of the session.

An extension belongs to the database, not to the namespace of one
connection. A connection opened with the connect key C<schema>
(L<DBIO::PostgreSQL/ONE SCHEMA CLASS IN SEVERAL NAMESPACES>) has its
namespace first in the C<search_path>, and C<postgis> cannot be moved to
another schema once it is installed. So when the schema chosen for the
extension is the namespace of the connection -- declared so, or C<public> on
a connection that works in C<public> -- this method throws a
L<DBIO::Exception> and sends no statement; declare another schema for the
extension.

The schema itself is not created here: one the database does not have is the
server's error. An extension that is installed already stays in the schema it
is in.

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

=head2 async_layer_class

  my $async_layer = DBIO::PostgreSQL::PostGIS::Storage->async_layer_class($mode);   # undef

Answers the core async-mirror resolver: returns C<undef> for every async mode,
declaring this layer deliberately sync-only (see L</No async layer>). Defining
the method is the statement; core skips the layer without probing a
C<::Async> sibling, instead of relying on the transitional silent skip for
layers that say nothing.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
