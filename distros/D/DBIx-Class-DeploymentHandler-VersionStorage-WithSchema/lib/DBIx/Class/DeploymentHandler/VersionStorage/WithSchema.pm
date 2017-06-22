use strict;
use warnings;
package DBIx::Class::DeploymentHandler::VersionStorage::WithSchema;

# ABSTRACT: Version storage for DeploymentHandler that includes the schema

use Moose;
use DBIx::Class::DeploymentHandler::LogImporter ':log';
use DBIx::Class::DeploymentHandler::VersionStorage::WithSchema::VersionResult;
our $VERSION = '0.001';

has schema => (
    is => 'ro',
    required => 1,
);

has version_rs => (
    isa => 'DBIx::Class::ResultSet',
    is => 'ro',
    builder => '_build_version_rs',
    handles => [qw/version_storage_is_installed/],
);

with 'DBIx::Class::DeploymentHandler::HandlesVersionStorage';

sub _build_version_rs {
  $_[0]->schema->register_class(
    __VERSION =>
      'DBIx::Class::DeploymentHandler::VersionStorage::WithSchema::VersionResult'
  );

  return $_[0]->schema->resultset('__VERSION')
}

sub database_version {
    my $self = shift;
    my $schema = ref $self->schema;
    return $self->version_rs->search({ schema => $schema })->latest->get_column('version');
}

sub add_database_version {
    my $self = shift;
    my $version = $_[0]->{version};

    my $schema = ref $self->schema;

    log_debug { "Adding version $version to schema $schema" };
    $self->version_rs->create({ %{ $_[0] }, schema => $schema });
}

sub delete_database_version {
    my $self = shift;
    my $version = $_[0]->{version};

    my $schema = ref $self->schema;

    log_debug { "Deleting version $version from schema $schema" };
    $self->version_rs->search({ version => $version, schema => $schema })->delete;
}

__PACKAGE__->meta->make_immutable;

1;

=head1 DESCRIPTION

The standard DeploymentHandler storage only stores the version of the schema.
This means you can't deploy multiple DH-handled DBIC schemata into the same
database.

This module has an extra column to store the schema that it is deploying as well
as the version.

To use it, you'll have to create a new subclass of
L<DBIx::Class::DeploymentHandler::Dad> that uses this module instead of the
standard one, and instantiate that in your script instead.

=head1 SEE ALSO

This module implements L<DBIx::Class::DeploymentHandler::HandlesVersionStorage>
and is similar to L<DBIx::Class::DeploymentHandler::VersionStorage::Standard>.
