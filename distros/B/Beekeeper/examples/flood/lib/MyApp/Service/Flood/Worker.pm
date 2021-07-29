package MyApp::Service::Flood::Worker;

use strict;
use warnings;

use Beekeeper::Worker ':log';
use base 'Beekeeper::Worker';


sub authorize_request {
    my ($self, $req) = @_;

    return BKPR_REQUEST_AUTHORIZED;
}

sub on_startup {
    my $self = shift;

    $self->accept_remote_calls(
        'myapp.flood.echo'  => 'echo',
        'myapp.flood.delay' => 'delayed_echo',
    );

    $self->accept_notifications(
        'myapp.flood.msg'   => 'message',
    );

    log_info "Ready";
}

sub on_shutdown {
    my $self = shift;

    log_info "Stopped";
}


sub echo {
    my ($self, $params) = @_;

    return $params;
}

sub message {
    my ($self, $params) = @_;
}

sub delayed_echo {
    my ($self, $params, $request) = @_;

    $request->async_response;

    my $timer_id = ++($self->{timer_seq});

    $self->{$timer_id} = AnyEvent->timer(
        after => 1,
        cb => sub {
            delete $self->{$timer_id};
            $request->send_response( $params );
        },
    );
}

1;
