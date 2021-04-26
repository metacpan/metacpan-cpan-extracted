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

    $self->accept_jobs(
        'test.signal' => 'signal',
        'test.fail'   => 'fail',
        'test.sleep'  => '_sleep',
        'test.fib1'   => 'fibonacci_1',
        'test.fib2'   => 'fibonacci_2',
        'test.echo'   => 'echo',
    );
}

sub authorize_request {
    my ($self, $req) = @_;

    return REQUEST_AUTHORIZED;
}

sub catchall {
    my ($self, $params) = @_;
    $self->signal($params);
}

sub signal {
    my ($self, $params) = @_;

    my ($signal) = $params->{signal} =~ m/(\w+)/;  # untaint
    my ($pid)    = $params->{pid}    =~ m/(\d+)/;

    sleep(rand() / 100); # helps to avoid signal races

    kill( $signal, $pid );
}

sub fail {
    my ($self, $params) = @_;

    warn $params->{warn} if $params->{warn};

    die $params->{die} if $params->{die};

    die Beekeeper::JSONRPC::Error->server_error( message => $params->{error}) if $params->{error};
}

sub _sleep {
    my ($self, $params) = @_;

    sleep $params;
}

sub fibonacci_1 {
    my ($self, $n) = @_;

    return $n if ($n <= 1);

    my $resp1 = $self->do_job(
        method  => 'test.fib1',
        params  => $n - 1,
        timeout => 3,
    );

    my $resp2 = $self->do_job(
        method  => 'test.fib1',
        params  => $n - 2,
        timeout => 3,
    );

    return $resp1->result + $resp2->result; 
}

sub fibonacci_2 {
    my ($self, $n) = @_;

    return $n if ($n <= 1);

    my $req1 = $self->do_async_job(
        method  => 'test.fib2',
        params  => $n - 1,
        timeout => 3,
    );

    my $req2 = $self->do_async_job(
        method  => 'test.fib2',
        params  => $n - 2,
        timeout => 3,
    );

    $self->wait_all_jobs;

    return $req1->result + $req2->result; 
}

sub echo {
    my ($self, $params) = @_;

    return $params;
}

1;
