package Datahub::Factory::Exporter::Datahub;

use strict;
use warnings;

use Datahub::Factory::Sane;

use Moo;
use Catmandu;
use namespace::clean;

with 'Datahub::Factory::Exporter';

has datahub_url         => (is => 'ro', required => 1);
has datahub_format      => (is => 'ro', default => sub { return 'LIDO'; });
has oauth_client_id     => (is => 'ro', required => 1);
has oauth_client_secret => (is => 'ro', required => 1);
has oauth_username      => (is => 'ro', required => 1);
has oauth_password      => (is => 'ro', required => 1);

sub _build_out {
    my $self = shift;
    my $store = Catmandu->store(
        'Datahub',
        url           => $self->datahub_url,
        client_id     => $self->oauth_client_id,
        client_secret => $self->oauth_client_secret,
        username      => $self->oauth_username,
        password      => $self->oauth_password
    );
    return $store;
}

sub add {
    my ($self, $item) = @_;
    $self->out->add($item);
}

1;
