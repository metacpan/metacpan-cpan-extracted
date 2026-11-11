use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use IO::Socket::INET ();
use Time::HiRes ();
use ClamAV::Clamd;
use FakeClamd;

# The commands with a one-line answer, and the ways a connection can go
# wrong before any answer arrives - every one of them from a peer this
# file controls.

plan skip_all => 'needs UNIX sockets' unless ClamAV::Clamd::_sun_path_max();

# --- the answers ------------------------------------------------------------
{
    my $srv = FakeClamd->new(mode => 'literal', literal => 'ClamAV 1.5.4/27000/Thu Nov  5 2026');
    my $c   = ClamAV::Clamd->new(socket => $srv->path);
    is $c->version, 'ClamAV 1.5.4/27000/Thu Nov  5 2026', 'version hands back the line';
    is $c->stats, 'ClamAV 1.5.4/27000/Thu Nov  5 2026', 'stats hands back whatever came';
    $srv->stop;

    $srv = FakeClamd->new(mode => 'literal', literal => 'ClamAV 1.5.4/27000/');
    $c   = ClamAV::Clamd->new(socket => $srv->path);
    is $c->version, 'ClamAV 1.5.4/27000/', 'a version line as long as the refusal is a version';
    $srv->stop;

    $srv = FakeClamd->new(mode => 'literal', literal => 'RELOADING');
    $c   = ClamAV::Clamd->new(socket => $srv->path);
    ok $c->reload, 'reload is true on RELOADING';
    $srv->stop;
}

# --- a reply that is not the one word asked for -------------------------------
{
    my $srv = FakeClamd->new(mode => 'literal', literal => 'NOPE');
    my $c   = ClamAV::Clamd->new(socket => $srv->path);
    ok !defined $c->ping, 'ping is undef on a reply other than PONG';
    is $c->error_code, ClamAV::Clamd::ERR_IO, '  reported as a protocol failure';
    like $c->error, qr/unexpected reply to PING: NOPE/, '  quoting the reply';
    ok !defined $c->reload, 'reload is undef on a reply other than RELOADING';
    like $c->error, qr/unexpected reply to RELOAD: NOPE/, '  quoting it too';
    $srv->stop;
}

# --- a reply that ends with the connection, not a terminator -----------------
{
    my $srv = FakeClamd->new(mode => 'unterminated');
    my $c   = ClamAV::Clamd->new(socket => $srv->path);
    ok $c->ping, 'PONG followed by a close is still PONG' or diag $c->error;
    $srv->stop;
}

# --- a ceiling smaller than the reply --------------------------------------------
{
    my $srv = FakeClamd->new(mode => 'ok');
    my $c   = ClamAV::Clamd->new(socket => $srv->path, reply_max => 3);
    ok !defined $c->ping, 'PING refused when PONG exceeds reply_max';
    is $c->error_code, ClamAV::Clamd::ERR_TOOBIG, '  reported as too big';
    $srv->stop;
}

# --- newline framing ------------------------------------------------------------
{
    my $srv = FakeClamd->new(mode => 'ok');
    my $c   = ClamAV::Clamd->new(socket => $srv->path, frame => 'n');
    ok $c->ping, 'nPING is answered PONG newline' or diag $c->error;
    is $c->scan('x')->state, 'clean', '  and a stream under newline framing scans';
    $srv->stop;

    $srv = FakeClamd->new(mode => 'literal', literal => 'ClamAV 1.5.4');
    $c   = ClamAV::Clamd->new(socket => $srv->path, frame => 'n');
    is $c->version, 'ClamAV 1.5.4', '  version under newline framing';
    $srv->stop;
}

# --- over TCP, against the forked fake ------------------------------------------
{
    my $srv = FakeClamd->new(mode => 'ok', tcp => 1);
    my $c   = ClamAV::Clamd->new($srv->target);
    ok $c->ping, 'ping over TCP' or diag $c->error;
    is $c->scan('x')->state, 'clean', '  and a stream over TCP';
    $srv->stop;
}

# --- a host that does not resolve ---------------------------------------------------
{
    my $c = ClamAV::Clamd->new(host => 'no.such.host.invalid', connect_timeout => 2);
    ok !defined $c->ping, 'a host that does not resolve fails';
    is $c->error_code, ClamAV::Clamd::ERR_CONNECT, '  as a connect error';
    like $c->error, qr/resolve/, '  naming the resolver';
}

# --- an address no TCP connect can reach ----------------------------------------------
{
    my $c = ClamAV::Clamd->new(host => '224.0.0.1', connect_timeout => 2);
    ok !defined $c->ping, 'a multicast address fails';
    is $c->error_code, ClamAV::Clamd::ERR_CONNECT, '  as a connect error';
}

# --- a connect that never completes --------------------------------------------------
# A listener whose backlog is full drops the handshake on the floor, so the
# client's SYN is never answered: the connect timeout is the only way out.
{
    my $l = IO::Socket::INET->new(
        Listen => 1, LocalAddr => '127.0.0.1', LocalPort => 0, Proto => 'tcp',
    ) or die "listen: $!";
    my @fill = map {
        IO::Socket::INET->new(
            PeerAddr => '127.0.0.1', PeerPort => $l->sockport, Proto => 'tcp', Blocking => 0,
        )
    } 1 .. 8;
    select undef, undef, undef, 0.1;

    my $c  = ClamAV::Clamd->new(host => '127.0.0.1', port => $l->sockport, connect_timeout => 0.3);
    my $t0 = Time::HiRes::time();
    my $r  = $c->ping;
    my $el = Time::HiRes::time() - $t0;
    ok !defined $r, 'a connect that is never completed does not succeed';
    is $c->error_code, ClamAV::Clamd::ERR_TIMEOUT, '  reported as a timeout';
    like $c->error, qr/connect timed out/, '  naming the connect';
    cmp_ok $el, '<', 10, '  within the configured timeout';

    $c = ClamAV::Clamd->new(host => '127.0.0.1', port => $l->sockport, connect_timeout => 1e-9);
    ok !defined $c->ping, 'a connect whose deadline has passed before the wait begins';
    is $c->error_code, ClamAV::Clamd::ERR_TIMEOUT, '  is a timeout too';
    close $_ for grep { defined } @fill;
    close $l;
}

# --- the deadline, met in every way it can be ---------------------------------------
{
    my $srv = FakeClamd->new(mode => 'stall');

    my $c = ClamAV::Clamd->new(socket => $srv->path, reply_timeout => 1e-9);
    ok !defined $c->ping, 'a deadline already past when the wait begins';
    is $c->error_code, ClamAV::Clamd::ERR_TIMEOUT, '  is a timeout';

    $c = ClamAV::Clamd->new(socket => $srv->path, reply_timeout => 0.0005);
    ok !defined $c->ping, 'a deadline under a millisecond away';
    is $c->error_code, ClamAV::Clamd::ERR_TIMEOUT, '  is a timeout';

    my $v = ClamAV::Clamd->new(socket => $srv->path, reply_timeout => 0.3)->scan('x');
    is $v->state, 'error', 'a blocking scan against a silent peer';
    like $v->error, qr/timed out waiting for clamd/, '  times out waiting';

    $srv->stop;
}

# --- a signal during the wait ---------------------------------------------------------
# The wait restarts against the deadline, not against the original
# timeout, or a stream of signals turns a one second wait into forever.
SKIP: {
    skip 'no interval timers here', 3 unless Time::HiRes->can('setitimer');
    my $srv = FakeClamd->new(mode => 'stall');
    my $c   = ClamAV::Clamd->new(socket => $srv->path, reply_timeout => 0.5);

    my $alarms = 0;
    local $SIG{ALRM} = sub { $alarms++ };
    Time::HiRes::setitimer(Time::HiRes::ITIMER_REAL(), 0.02, 0.02);
    my $t0 = Time::HiRes::time();
    my $r  = $c->ping;
    my $el = Time::HiRes::time() - $t0;
    Time::HiRes::setitimer(Time::HiRes::ITIMER_REAL(), 0, 0);

    ok !defined $r, 'a wait peppered with signals still times out';
    is $c->error_code, ClamAV::Clamd::ERR_TIMEOUT, '  as a timeout';
    cmp_ok $el, '<', 10, "  against the deadline, not restarted from scratch ($alarms signals)";
    $srv->stop;
}

done_testing;
