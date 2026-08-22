use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use Time::HiRes ();
use ClamAV::Clamd;
use FakeClamd;

# Everything here runs against a listener we control, so it runs
# everywhere - no clamd required, and it can produce failures a real
# clamd cannot be made to produce.

plan skip_all => 'needs UNIX sockets' unless ClamAV::Clamd::_sun_path_max();

# --- a well-behaved peer -----------------------------------------------
{
    my $srv = FakeClamd->new(mode => 'ok');
    my $c   = ClamAV::Clamd->new(socket => $srv->path);
    ok $c->ping, 'ping against a cooperative peer' or diag $c->error;
    $srv->stop;
}

# --- connect to nothing ------------------------------------------------
{
    my $c = ClamAV::Clamd->new(socket => '/tmp/cc-definitely-not-here.sock');
    ok !$c->ping, 'ping fails when nothing is listening';
    is $c->error_code, ClamAV::Clamd::ERR_CONNECT, '  reported as a connect error';
    like $c->error, qr/connect/, '  message names the operation';
}

# --- a peer that accepts and never answers -----------------------------
# Assert the BOUND, not the value: a fixed "took about 1 second" fails on
# a loaded smoker. What matters is that it fired, that it did not fire
# instantly, and that the verdict is an error rather than a success.
{
    my $srv = FakeClamd->new(mode => 'stall');
    my $c   = ClamAV::Clamd->new(socket => $srv->path, reply_timeout => 1);

    my $t0 = Time::HiRes::time();
    my $r  = $c->ping;
    my $el = Time::HiRes::time() - $t0;

    ok !$r, 'a stalled peer does not produce a success';
    is $c->error_code, ClamAV::Clamd::ERR_TIMEOUT, '  reported as a timeout';
    cmp_ok $el, '>=', 0.9,  '  did not give up early';
    cmp_ok $el, '<',  20,   '  did fire rather than hang forever';
    $srv->stop;
}

# --- a generous timeout must NOT fire ----------------------------------
{
    my $srv = FakeClamd->new(mode => 'slow');
    my $c   = ClamAV::Clamd->new(socket => $srv->path, reply_timeout => 30);
    ok $c->ping, 'a slow but answering peer succeeds' or diag $c->error;
    $srv->stop;
}

# --- a reply that never ends -------------------------------------------
# The ceiling is the difference between a bounded read and an allocation
# loop driven by the peer.
{
    my $srv = FakeClamd->new(mode => 'flood');
    my $c   = ClamAV::Clamd->new(
        socket => $srv->path, reply_max => 64 * 1024, reply_timeout => 10,
    );
    ok !$c->ping, 'an unterminated reply does not succeed';
    is $c->error_code, ClamAV::Clamd::ERR_TOOBIG, '  refused at the ceiling';
    like $c->error, qr/ceiling/, '  message says why';
    $srv->stop;
}

# --- a peer that hangs up without replying -----------------------------
{
    my $srv = FakeClamd->new(mode => 'hangup');
    my $c   = ClamAV::Clamd->new(socket => $srv->path);
    ok !$c->ping, 'a peer that closes without replying does not succeed';
    is $c->error_code, ClamAV::Clamd::ERR_CLOSED, '  reported as a closed connection';
    $srv->stop;
}

# --- failures never look like success ----------------------------------
# The whole point: no transport failure may be mistaken for a good
# answer. ping returns undef, never 0-but-true or an empty string.
{
    for my $mode (qw(stall flood hangup)) {
        my $srv = FakeClamd->new(mode => $mode);
        my $c   = ClamAV::Clamd->new(
            socket => $srv->path, reply_timeout => 1, reply_max => 4096,
        );
        my $r = $c->ping;
        ok !defined $r, "$mode: ping returns undef, not a false-but-defined value";
        ok defined $c->error && length $c->error, "$mode: an error message is set";
        ok defined $c->error_code && $c->error_code != 0, "$mode: a non-zero code is set";
        $srv->stop;
    }
}

done_testing;
