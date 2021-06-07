package MyApp::Service::Chat;

use strict;
use warnings;

use Beekeeper::Client;
use Time::HiRes 'time';


sub new {
    my $class = shift;
    bless {}, $class;
}

sub client {
    my $proto = shift;

    Beekeeper::Client->instance;
}


# This is the API of service MyApp::Service::Chat

sub send_message {
    my ($self, %args) = @_;

    $self->client->call_remote(
        method => 'myapp.chat.message',
        params => {
            message => $args{'message'},
        },
    );
}

sub send_private_message {
    my ($self, %args) = @_;

    $self->client->call_remote(
        method  => 'myapp.chat.pmessage',
        params  => {
            to_user => $args{'to_user'},
            message => $args{'message'},
        },
    );
}

sub send_notice {
    my ($self, %args) = @_;

    $self->client->call_remote(
        method  => 'myapp.chat.notice',
        params  => {
            to_uuid => $args{'to_uuid'},
            message => $args{'message'},
        },
    );
}

sub ping {
    my ($self) = @_;

    my $start = time;

    $self->client->call_remote( method => 'myapp.chat.ping' );

    my $took = time - $start;

    return sprintf("%.1f", $took * 1000);
}

sub receive_messages {
    my ($self, %args) = @_;

    my $callback = $args{'callback'};

    die "Callback must be a coderef" unless (ref $callback eq 'CODE');

    $self->client->accept_notifications(
        'myapp.chat.*' => sub { 
            my $params = shift;
            $callback->(
                message => $params->{'message'},
                from    => $params->{'from'},
            );
        },
    );
}

1;
