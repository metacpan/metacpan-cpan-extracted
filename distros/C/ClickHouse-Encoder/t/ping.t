use strict;
use warnings;
use Test::More;
use lib 'blib/lib', 'blib/arch', 't/lib';
use ClickHouse::Encoder;

# ping() should fail fast against a port nothing is listening on, and
# the error must be catchable + carry the network reason. The point of
# the test isn't the exact 599 wording (HTTP::Tiny's "Internal Exception"
# format has shifted across versions) but that ping croaks with a useful
# message rather than returning a false success.
{
    # Pick a port likely to be closed; the kernel returns ECONNREFUSED
    # immediately, so the 1s timeout below is for the worst case.
    local $@;
    eval {
        ClickHouse::Encoder->ping(
            host    => '127.0.0.1',
            port    => 1,
            timeout => 1,
        );
    };
    ok($@, 'ping: closed port croaks');
    like($@, qr/ping:.*HTTP/i, 'ping: error mentions HTTP');
}

# Live CH server: live.t handles full end-to-end coverage; here we
# only need a smoke test for the path-not-Path against the local
# server when clickhouse-client says it's running. Skip silently
# otherwise so this unit test stays portable.
SKIP: {
    my $running = system("clickhouse-client --query 'select 1' "
                       . ">/dev/null 2>&1") == 0;
    skip 'no live ClickHouse on localhost:8123', 1 unless $running;
    my $ok = ClickHouse::Encoder->ping(host => '127.0.0.1', port => 8123);
    is($ok, 1, 'ping: returns 1 against a live server');
}

done_testing();
