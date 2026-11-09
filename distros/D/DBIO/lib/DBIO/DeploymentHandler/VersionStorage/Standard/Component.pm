package DBIO::DeploymentHandler::VersionStorage::Standard::Component;
# ABSTRACT: Attach this component to your schema to ensure you stay up to date

use strict;
use warnings;

our $VERSION = '0.900004';

use DBIO::Carp;
use DBIO::DeploymentHandler::VersionStorage::Standard::VersionResult;

use namespace::clean;


sub attach_version_storage {
   $_[0]->register_class(
      __VERSION => 'DBIO::DeploymentHandler::VersionStorage::Standard::VersionResult'
   );
}


sub connection  {
  my $self = shift;
  $self->next::method(@_);

  $self->attach_version_storage;

  my $args = $self->storage->_dbio_connect_attributes; # fork-rename: was _dbic_connect_attributes

  unless ( $args->{ignore_version} || $ENV{DBIO_NO_VERSION_CHECK}) { # documented name; legacy DBIC_NO_VERSION_CHECK still honored in DBIO::Storage::DBI
    my $versions = $self->resultset('__VERSION');

    if (!$versions->version_storage_is_installed) {
       carp "Your DB is currently unversioned. Please call upgrade on your schema to sync the DB.\n";
    } elsif ($versions->database_version ne $self->schema_version) {
      carp 'Versions out of sync. This is ' . $self->schema_version .
        ', your database contains version ' . $versions->database_version . ", please call upgrade on your Schema.\n";
    }
  }

  return $self;
}

1;

# vim: ts=2 sw=2 expandtab

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::DeploymentHandler::VersionStorage::Standard::Component - Attach this component to your schema to ensure you stay up to date

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Schema component. Load it into a schema that is managed by
L<DBIO::DeploymentHandler>:

  __PACKAGE__->load_components(
    '+DBIO::DeploymentHandler::VersionStorage::Standard::Component'
  );

=head1 METHODS

=head2 attach_version_storage

Registers L<DBIO::DeploymentHandler::VersionStorage::Standard::VersionResult>
as the C<__VERSION> source of the schema.

=head2 connection

Component override. After the normal C<connection>, calls
L</attach_version_storage>, then -- unless the connect attributes carry
C<ignore_version> or C<DBIO_NO_VERSION_CHECK> is set in the environment --
carps if the database has no version table ("unversioned") or if its latest
version differs from the schema version. Returns the schema.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
