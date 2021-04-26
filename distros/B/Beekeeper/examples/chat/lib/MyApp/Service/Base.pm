package MyApp::Service::Base;

use strict;
use warnings;

use Beekeeper::Worker ':log';
use base 'Beekeeper::Worker';

use Carp;


# Common base class for all MyApp services

sub authorize_request {
    my ($self, $req) = @_;

    if ($req->{method} eq 'myapp.auth.login') {
        return REQUEST_AUTHORIZED;
    }

    my ($uuid) = $req->get_auth_tokens;

    return unless $uuid;

    return REQUEST_AUTHORIZED;
}

sub set_current_user_uuid {
    my ($self, $uuid) = @_;

    croak "Invalid uuid $uuid" unless ($uuid =~ m/^[\w-]+$/);

    $self->set_auth_tokens( $uuid, 'CHAT_USER' );
}

sub get_current_user_uuid {
    my $self = shift;

    my ($uuid) = $self->get_auth_tokens;

    return $uuid;
}

1;
