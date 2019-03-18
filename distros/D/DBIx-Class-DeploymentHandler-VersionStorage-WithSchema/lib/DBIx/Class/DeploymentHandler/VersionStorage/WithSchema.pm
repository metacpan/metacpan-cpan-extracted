use strict;
use warnings;
package DBIx::Class::DeploymentHandler::VersionStorage::WithSchema;

# ABSTRACT: Version storage for DeploymentHandler that includes the schema

use Moo;
use DBIx::Class::DeploymentHandler::LogImporter ':log';
use DBIx::Class::DeploymentHandler::VersionStorage::WithSchema::VersionResult;
our $VERSION = '0.004';

has schema => (
    is => 'ro',
    required => 1,
);

has version_rs => (
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
    $self->version_rs->search({ schema => $schema }, {
        order_by => { -desc => 'id' },
        rows => 1
    })->get_column('version')->next;
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

=head1 SYNOPSIS

To use it, you'll have to create a new subclass of
L<DBIx::Class::DeploymentHandler::Dad> that uses this module instead of the
standard one, and instantiate that in your script instead.

    # See t/lib/Dad.pm for a working example
    package My::DH::Dad;

    use Moose;
    extends 'DBIx::Class::DeploymentHandler::Dad';

    with 'DBIx::Class::DeploymentHandler::WithApplicatorDumple' => {
      ...
      'DBIx::Class::DeploymentHandler::WithApplicatorDumple' => {
        interface_role       => 'DBIx::Class::DeploymentHandler::HandlesVersionStorage',
        class_name           => 'DBIx::Class::DeploymentHandler::VersionStorage::WithSchema',
        delegate_name        => 'version_storage',
        attributes_to_assume => ['schema'],
      };

    # in a script ...
    my $handler = My::DH::Dad->new( ... );

    # For the "core" schema (see below)
    $handler->prepare_install( core => 1 );
    $handler->install;

    # For modules
    $handler->prepare_install;
    my $ddl = $handler->deploy;
    $handler->add_schema_version({
        ddl => $ddl,
        version => $schema->to_version
    });

The original idea behind this module is that you could merge any number of
schemata together to create one big one, and DH would keep track of the version
of each schema. However, DH won't support that easily, so instead, you'll have
to have a single "core" module, and any number of modular schemata installed
into it.

The reason for this is that DH tries to install a version table for every schema
and we can't avoid it. To bypass this problem we define a I<core> schema, which
contains the C<version> table, and other schemata that don't.

When you prepare the installation files for your core schema you should tell
your Dad subclass that you are doing so. This will usually only happen once
ever, because once you've created your core schema's first version you're
golden. This is the only time you will I<install> a schema.

    $handler->prepare_install( core => 1 );
    $handler->install;

When you prepare the installation files for a module schema, you run
C<prepare_install> without that extra argument.

    $handler->prepare_install;

This ensures that the first version of your module doesn't contain a
C<__VERSION> SQL file, and thus it won't immediately crash when you deploy it.
Speaking of deploy, you can't C<install> this schema because DH will die. You
have to C<deploy> it.

    $handler->deploy;

When you deploy a schema like this, DH doesn't record the version, so you have
to do that yourself. You can get the DDL out of the deploy step.

    my $ddl = $handler->deploy;
    $handler->add_schema_version({
        ddl => $ddl,
        version => $schema->to_version
    });

=head1 SEE ALSO

This module implements L<DBIx::Class::DeploymentHandler::HandlesVersionStorage>
and is similar to L<DBIx::Class::DeploymentHandler::VersionStorage::Standard>.
