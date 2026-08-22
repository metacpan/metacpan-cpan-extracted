use strict;
use warnings;
use Test::More;
use ClamAV::Clamd;

# The suite against a real clamd. Skipped unless one is reachable, which
# is most of the time - so nothing here may be the only coverage of
# anything. Its job is the things a fake cannot prove: that the framing
# this client sends is the framing a real clamd accepts.

my $sock = $ENV{CLAMD_SOCKET};
my $host = $ENV{CLAMD_HOST};
my $port = $ENV{CLAMD_PORT} || 3310;

unless ($sock || $host) {
    for my $p (qw(
        /var/run/clamav/clamd.ctl
        /run/clamav/clamd.ctl
        /var/run/clamav/clamd.sock
        /run/clamav/clamd.sock
        /tmp/clamd.socket
        /opt/homebrew/var/run/clamav/clamd.sock
        /usr/local/var/run/clamav/clamd.sock
    )) {
        next unless -S $p;
        next if length($p) >= (ClamAV::Clamd::_sun_path_max() || 0);
        $sock = $p;
        last;
    }
}

plan skip_all => 'no clamd reachable (set CLAMD_SOCKET or CLAMD_HOST)'
    unless $sock || $host;

# Probe BEFORE asserting anything. skip_all after a test has already run
# is a harness error, not a skip - so a configured-but-dead clamd would
# turn a clean skip into a failure.
my $c = eval {
    $sock ? ClamAV::Clamd->new(socket => $sock)
          : ClamAV::Clamd->new(host => $host, port => $port);
};
plan skip_all => "cannot construct a client: $@" unless $c;
plan skip_all => 'clamd configured but not answering: ' . ($c->error // '?')
    unless $c->ping;

pass 'PING against a real clamd';

my $v = $c->version;
ok defined $v, 'VERSION returns something' or diag $c->error;
like $v, qr/^ClamAV /, '  and it looks like a version string';

my $s = $c->stats;
ok defined $s, 'STATS returns something' or diag $c->error;
like $s, qr/THREADS/, '  and mentions the thread pool';

# The reply terminator follows the request framing - measured in phase 0,
# asserted here so a future clamd changing it is caught rather than
# turning into a hang.
{
    my $n = $sock
        ? ClamAV::Clamd->new(socket => $sock, frame => 'n')
        : ClamAV::Clamd->new(host => $host, port => $port, frame => 'n');
    ok $n->ping, 'newline framing also works' or diag $n->error;
}

# A ceiling smaller than the reply must refuse rather than truncate:
# a truncated reply is a verdict with its ending cut off.
{
    my $tiny = $sock
        ? ClamAV::Clamd->new(socket => $sock, reply_max => 4)
        : ClamAV::Clamd->new(host => $host, port => $port, reply_max => 4);
    ok !defined $tiny->stats, 'STATS refused when it exceeds reply_max';
    is $tiny->error_code, ClamAV::Clamd::ERR_TOOBIG, '  reported as too big';
}

done_testing;
