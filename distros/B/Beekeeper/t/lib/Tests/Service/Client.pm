package Tests::Service::Client;

use Beekeeper::Client;

sub notify {
    my ($class, $method, $params) = @_;

    my $cli = Beekeeper::Client->instance;

    $cli->send_notification(
        method => $method,
        params => $params,
    );
}

sub signal {
    my ($class, $signal, $pid) = @_;

    my $cli = Beekeeper::Client->instance;

    $cli->send_notification(
        method => 'test.signal',
        params => { signal => $signal, pid => $pid },
    );
}

sub fail {
    my ($class, %args) = @_;

    my $cli = Beekeeper::Client->instance;

    $cli->do_job(
        method => 'test.fail',
        params => { %args },
    );
}

sub sleep {
    my ($class, $time) = @_;

    my $cli = Beekeeper::Client->instance;

    $cli->do_job(
        method => 'test.sleep',
        params => $time,
    );
}

sub fibonacci_1 {
    my ($class, $n) = @_;

    my $cli = Beekeeper::Client->instance;

    $cli->do_job(
        method => 'test.fib1',
        params => $n,
    );
}

sub fibonacci_2 {
    my ($class, $n) = @_;

    my $cli = Beekeeper::Client->instance;

    $cli->do_job(
        method => 'test.fib2',
        params => $n,
    );
}

sub echo {
    my ($class, $params ) = @_;

    my $cli = Beekeeper::Client->instance;

    $cli->do_job(
        method => 'test.echo',
        params => $params,
    );
}

1;
