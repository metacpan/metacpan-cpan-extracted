package Datahub::Factory::Importer::Datahub;

use strict;
use warnings;

use Moo;
use Catmandu;

with 'Datahub::Factory::Importer';

has datahub_url         => (is => 'ro', required => 1);
has oauth_client_id     => (is => 'ro', required => 1);
has oauth_client_secret => (is => 'ro', required => 1);
has oauth_username      => (is => 'ro', required => 1);
has oauth_password      => (is => 'ro', required => 1);

sub _build_importer {
    my $self = shift;
    my $d = Catmandu->store('Datahub',
        url           => $self->datahub_url,
        client_id     => $self->oauth_client_id,
        client_secret => $self->oauth_client_secret,
        username      => $self->oauth_username,
        password      => $self->oauth_password
    );
    return $d->bag;
}

1;
__END__