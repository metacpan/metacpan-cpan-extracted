package MyApp::Service::Auth;

use strict;
use warnings;

use Beekeeper::Client;


sub new {
    my $class = shift;
    bless {}, $class;
}

sub client {
    my $proto = shift;

    Beekeeper::Client->instance;
}


# This is the API of service MyApp::Service::Auth

sub login {
    my ($self, %args) = @_;

    $self->client->do_job(
        method => 'myapp.auth.login',
        params => {
            username => $args{'username'},
            password => $args{'password'},
        },
    );
}

sub logout {
    my ($self) = @_;

    $self->client->do_job(
        method => 'myapp.auth.logout',
    );
}

sub kick {
    my ($self, %args) = @_;

    $self->client->do_job(
        method => 'myapp.auth.kick',
        params => { 
            username => $args{'username'},
        },
    );
}

1;
