package Datahub::Factory::Module::PID::CloudFiles;

use strict;
use warnings;

use Moo;
use Catmandu;

use WebService::Rackspace::CloudFiles;

with 'Datahub::Factory::Module::PID::File';

has username       => (is => 'ro', required => 1);
has api_key        => (is => 'ro', required => 1);
has container_name => (is => 'ro', default => 'datahub');
has object         => (is => 'ro', required => 1);

has client    => (is => 'lazy');
has container => (is => 'lazy');

sub _build_path {
    my $self = shift;
    return $self->get_object($self->object);
}

sub _build_client {
    my $self = shift;
    return WebService::Rackspace::CloudFiles->new(
        user => $self->username,
        key  => $self->api_key
    );
}

sub _build_container {
    my $self = shift;
    return $self->client->container(name => $self->container_name);
}

sub get_object {
    my ($self, $object_name) = @_;
    my $object = $self->container->object(name => $object_name);
    my $file_name = $object_name;
    $file_name =~ s/[^A-Za-z0-9\-\.]/./g;
    $object->get_filename(sprintf('/tmp/%s', $file_name));
    return sprintf('/tmp/%s', $file_name);
}

1;