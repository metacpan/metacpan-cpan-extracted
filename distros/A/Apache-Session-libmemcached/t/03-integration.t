use strict;
use warnings;

use Test::More qw/no_plan/;
use constant PORT_POOL1 => (2110, 2111);
use constant PORT_POOL2 => (2112, 2113);
use constant SERVERS_BY_POOL => 2;


use Apache::Session::libmemcached;

SKIP: {

    unless (grep { -x "$_/memcached" } split /:/, $ENV{PATH}) {
        skip('memcached is not in $PATH', 1);
    }

    my @server_pids;
    for my $port (PORT_POOL1, PORT_POOL2) {
        if (my $pid = fork()) {
            push (@server_pids, $pid);
        }
        else {
            exec("memcached -p $port");
        }
    }

    unless (@server_pids == (PORT_POOL1 + PORT_POOL2)) {
        diag('Cannot launch all memcached server');
        kill(15, @server_pids);
        exit(0);
    }

    sleep(2);
    my $pools = [
        [ map { "127.0.0.1:$_" } PORT_POOL1 ],
        [ map { "127.0.0.1:$_" } PORT_POOL2 ]
    ];

    my $session;

    for (1..100) {
            my ($key, $value) = (int(rand(1000)), int(rand(1000)));
            tie %{$session}, 'Apache::Session::libmemcached', undef, {
                load_balance_pools => $pools,
                expiration => '300',
            };

            # Insert session info
            my $sid = $session->{_session_id};
            $session->{$key} = $value;
            untie %{$session};

            # Test we can retrieve session info
            tie %{$session}, 'Apache::Session::libmemcached', $sid, {
                load_balance_pools => $pools,
                expiration => '300',
                log_errors => 1,
            };
            ok($session->{$key} == $value);
            untie %{$session};
    }

    for (1..100) {
            my ($key, $value) = (int(rand(1000)), int(rand(1000)));
            tie %{$session}, 'Apache::Session::libmemcached', undef, {
                load_balance_pools => $pools,
                expiration => '300',
                failover => 1,
                log_errors => 1,
            };

            # Insert session info
            my $sid = $session->{_session_id};
            $session->{$key} = $value;
            untie %{$session};

            # Test we can retrieve session info
            tie %{$session}, 'Apache::Session::libmemcached', $sid, {
                load_balance_pools => $pools,
                expiration => '300',
                failover => 1,
            };
            ok($session->{$key} == $value);
            untie %{$session};
    }

    tie %{$session}, 'Apache::Session::libmemcached', undef, {
        load_balance_pools => $pools,
        expiration => '300',
        failover => 1,
        log_errors => 1,
    };

    # Insert session info
    my $sid = $session->{_session_id};
    $session->{foo} = 'bar';
    untie %{$session};

    # Kill servers containing the key
    my $idx = hex(substr($sid, 0, 1)) % 2;
    my $start = SERVERS_BY_POOL * $idx;
    my $end = $start + SERVERS_BY_POOL - 1;
    for my $i ($start..$end) {
        kill (15, $server_pids[$i]);
    }

    sleep(2);

    # Test we can retrieve session info from a back up server
    tie %{$session}, 'Apache::Session::libmemcached', $sid, {
        load_balance_pools => $pools,
        expiration => '300',
        failover => 1,
    };
    ok($session->{foo} eq 'bar');
    untie %{$session};

    kill(15, @server_pids);
}


