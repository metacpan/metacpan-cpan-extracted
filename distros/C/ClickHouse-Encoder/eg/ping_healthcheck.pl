#!/usr/bin/env perl
# Wait for a ClickHouse server to become reachable before starting an
# ingest job. ping() hits the /ping endpoint and croaks on connection
# refused / timeout / non-2xx, so a retry loop around it is a clean
# readiness gate for orchestration scripts and container entrypoints.
#
# Usage:
#     perl eg/ping_healthcheck.pl --host=db --port=8123 [--tries=30]

use strict;
use warnings;
use Getopt::Long;
use Time::HiRes ();
use ClickHouse::Encoder;

my ($host, $port, $tries, $delay) = ('127.0.0.1', 8123, 30, 1);
GetOptions('host=s' => \$host, 'port=i' => \$port,
           'tries=i' => \$tries, 'delay=f' => \$delay)
    or die "bad options\n";

my $up = 0;
for my $attempt (1 .. $tries) {
    if (eval { ClickHouse::Encoder->ping(
                   host => $host, port => $port, timeout => 2) }) {
        $up = 1;
        print "ClickHouse at $host:$port is up (attempt $attempt)\n";
        last;
    }
    # $@ carries the reason: connection refused, timeout, or HTTP error.
    chomp(my $why = $@);
    print "attempt $attempt/$tries: not ready ($why)\n";
    Time::HiRes::sleep($delay) if $attempt < $tries;
}

die "ClickHouse at $host:$port did not come up after $tries tries\n"
    unless $up;

# Server is ready - the real work would start here.
print "proceeding with ingest...\n";
