package MyApp::Service::Chat::Worker;

use strict;
use warnings;

use base 'MyApp::Service::Base';


sub on_startup {
    my $self = shift;

    $self->accept_jobs(
        'myapp.chat.message'  => 'send_message',
        'myapp.chat.pmessage' => 'send_private_message',
        'myapp.chat.notice'   => 'send_notice',
        'myapp.chat.ping'     => 'ping',
    );
}

sub send_message {
    my ($self, $params) = @_;

    my $msg  = $params->{'message'};
    my $from = $self->get_current_user_uuid;

    return unless (defined $msg && length $msg);

    # Broadcast to all frontend clients
    $self->send_notification(
        method  => 'myapp.chat.message',
        address => 'frontend',
        params  => { from => $from, message => $msg },
    );
}

sub send_private_message {
    my ($self, $params) = @_;

    # For simplicity, this example avoids resolving username <--> uuid 
    my $uuid = $params->{'to_user'};
    my $msg  = $params->{'message'};
    my $from = $self->get_current_user_uuid;

    return unless (defined $msg && length $msg);

    # Push notification to specific user
    $self->send_notification(
        method  => 'myapp.chat.pmessage',
        address => "frontend.user-$uuid",
        params  => { from => $from, message => $msg },
    );
}

sub send_notice {
    my ($self, $params) = @_;

    my $uuid = $params->{'to_uuid'};
    my $msg  = $params->{'message'};

    $self->send_notification(
        method  => 'myapp.chat.pmessage',
        address => "frontend.user-$uuid",
        params  => { message => $msg },
    );
}

sub ping {
    my ($self, $params) = @_;

    return 1;
}

1;
