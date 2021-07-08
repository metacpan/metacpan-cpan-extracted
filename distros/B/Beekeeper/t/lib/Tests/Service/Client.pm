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

    $cli->call_remote(
        method => 'test.fail',
        params => { %args },
    );
}

sub sleep {
    my ($class, $time) = @_;

    my $cli = Beekeeper::Client->instance;

    $cli->call_remote(
        method => 'test.sleep',
        params => $time,
    );
}

sub fibonacci {
    my ($class, $n) = @_;

    my $cli = Beekeeper::Client->instance;

    $cli->call_remote(
        method => 'test.fib4',
        params => $n,
    );
}

sub echo {
    my ($class, $params ) = @_;

    my $cli = Beekeeper::Client->instance;

    $cli->call_remote(
        method => 'test.echo',
        params => $params,
    );
}

1;
