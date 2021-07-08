package Tests::Service::Worker;

use strict;
use warnings;

use Beekeeper::Worker ':log';
use base 'Beekeeper::Worker';

use Time::HiRes 'sleep';

=pod

=head1 Test worker

Simple worker used to test Beekeeper framework.

=cut

sub on_startup {
    my $self = shift;

    $self->accept_notifications(
        'test.signal' => 'signal',
        'test.fail'   => 'fail',
        'test.echo'   => 'echo',
        'test.*'      => 'catchall',
    );

    $self->accept_remote_calls(
        'test.signal' => 'signal',
        'test.fail'   => 'fail',
        'test.sleep'  => '_sleep',
        'test.fact'   => 'factorial',
        'test.fib1'   => 'fibonacci_1',
        'test.fib2'   => 'fibonacci_2',
        'test.fib3'   => 'fibonacci_3',
        'test.fib4'   => 'fibonacci_4',
        'test.echo'   => 'echo',
    );
}

sub authorize_request {
    my ($self, $req) = @_;

    return BKPR_REQUEST_AUTHORIZED;
}

sub catchall {
    my ($self, $params) = @_;
    $self->signal($params);
}

sub signal {
    my ($self, $params) = @_;

    my ($signal) = $params->{signal} =~ m/(\w+)/;  # untaint
    my ($pid)    = $params->{pid}    =~ m/(\d+)/;

    my $sleep = exists $params->{after} ? $params->{after} : rand() * 2;

    sleep $sleep;

    kill( $signal, $pid );
}

sub fail {
    my ($self, $params) = @_;

    warn $params->{warn} if $params->{warn};

    die $params->{die} if $params->{die};

    die Beekeeper::JSONRPC::Error->server_error( message => $params->{error}) if $params->{error};
}

sub echo {
    my ($self, $params) = @_;

    return $params;
}

sub _sleep {
    my ($self, $params) = @_;

    sleep $params;
}

sub factorial {
    my ($self, $n) = @_;

    return $n if ($n <= 2);

    my $resp = $self->call_remote(
        method  => 'test.fact',
        params  => $n - 1,
    );

    return $resp->result * $n;
}

sub fibonacci_1 {
    my ($self, $n) = @_;

    return $n if ($n <= 1);

    my $resp1 = $self->call_remote(
        method  => 'test.fib1',
        params  => $n - 1,
    );

    my $resp2 = $self->call_remote(
        method  => 'test.fib1',
        params  => $n - 2,
    );

    return $resp1->result + $resp2->result; 
}

sub fibonacci_2 {
    my ($self, $n) = @_;

    return $n if ($n <= 1);

    my $req1 = $self->call_remote_async(
        method  => 'test.fib2',
        params  => $n - 1,
    );

    my $req2 = $self->call_remote_async(
        method  => 'test.fib2',
        params  => $n - 2,
    );

    $self->wait_async_calls;

    return $req1->result + $req2->result; 
}

sub fibonacci_3 {
    my ($self, $n, $req) = @_;

    return $n if ($n <= 1);

    $req->async_response;

    $self->call_remote_async(
        method  => 'test.fib3',
        params  => $n - 1,
        on_success => sub {

            my $fib_1 = $_[0]->result;

            $self->call_remote_async(
                method  => 'test.fib3',
                params  => $n - 2,
                on_success => sub {

                    my $fib_2 = $_[0]->result;

                    $req->send_response( $fib_1 + $fib_2 );
                },
            );
        },
    );
}

sub fibonacci_4 {
    my ($self, $n, $req) = @_;

    return $n if ($n <= 1);

    $req->async_response;

    my $sum = 0;

    my $cb = AE::cv sub {
        $req->send_response( $sum );
    };

    $cb->begin;

    $self->call_remote_async(
        method  => 'test.fib4',
        params  => $n - 1,
        on_success => sub {
            $sum += $_[0]->result;
            $cb->end;
        },
    );

    $cb->begin;

    $self->call_remote_async(
        method  => 'test.fib4',
        params  => $n - 2,
        on_success => sub {
            $sum += $_[0]->result;
            $cb->end;
        },
    );
}

1;
