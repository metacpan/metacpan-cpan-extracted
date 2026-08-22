use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use File::Temp ();
use ClamAV::Clamd;
use FakeClamd;

plan skip_all => 'needs UNIX sockets' unless ClamAV::Clamd::_sun_path_max();

my $dir = File::Temp->newdir();

# The two hazards INSTREAM has and FILDES does not, both provoked from a
# peer we control so they run everywhere. Neither can be produced from a
# real clamd on demand.

# --- a reply that arrives before the body is written ---------------------
# This is THE INSTREAM bug: clamd answers from chunk 3 of 400 and closes.
# A client that writes first and reads afterwards reports a transport
# error for a file clamd correctly identified as infected.
{
    my $srv = FakeClamd->new(mode => 'earlyreply');
    my $c   = ClamAV::Clamd->new(socket => $srv->path, reply_timeout => 10);

    my $big = 'x' x (4 * 1024 * 1024);      # many chunks at the 64 KiB default
    my $r   = $c->scan($big);

    ok !$r->is_error, 'a reply arriving mid-write is a verdict, not a failure'
        or diag 'error: ' . ($r->error // '?');
    is $r->state, 'infected', '  and it is the verdict the peer sent';
    is $r->signature, 'Eicar-Test-Signature', '  with the signature intact';
    $srv->stop;
}

# --- a peer that vanishes mid-stream with nothing to say -----------------
# Must be an error, must NOT be a clean verdict, and must not take the
# process down: writing to a closed socket raises SIGPIPE, whose default
# disposition kills the process. A scanner that kills its caller when
# clamd hangs up is unusable in a server, and clamd hangs up routinely.
{
    my $srv = FakeClamd->new(mode => 'cutoff');
    my $c   = ClamAV::Clamd->new(socket => $srv->path, reply_timeout => 10);

    my $big = 'y' x (8 * 1024 * 1024);
    my $r   = $c->scan($big);

    ok !$r->is_clean, 'a stream cut off without a verdict is not clean';
    is $r->state, 'unscannable', '  it is unscannable: nothing was scanned';
    is $r->reason, 'StreamMaxLength', '  with the likely cause named';
    is $c->error_code, ClamAV::Clamd::ERR_STREAMCUT, '  and the client records the cut';
    pass 'the process survived writing into a closed socket (no SIGPIPE)';
    $srv->stop;
}

# --- the write loop completes -------------------------------------------
# A small chunk size makes a modest file into many chunks, so this proves
# the loop runs to the end without needing a large fixture.
{
    my $srv = FakeClamd->new(mode => 'ok');
    my $c   = ClamAV::Clamd->new(socket => $srv->path, chunk => 1024, reply_timeout => 10);
    is $c->scan('z' x (256 * 1024))->state, 'clean', 'a 256-chunk stream completes';
    $srv->stop;
}

# --- an unrecognised reply is an ERROR, never clean ----------------------
# The parser's default. A reply in no shape it knows must not be
# optimistically read as "nothing found".
{
    my $srv = FakeClamd->new(mode => 'gibberish');
    my $c   = ClamAV::Clamd->new(socket => $srv->path, reply_timeout => 10);
    my $v   = $c->scan('anything');
    is $v->state, 'error', 'a reply in no known shape is an error';
    ok !$v->is_clean, '  and emphatically not clean';
    is $v->raw, 'WHAT IS THIS EVEN', '  with the raw reply kept for logging';
    $srv->stop;
}

# --- argument handling ---------------------------------------------------
{
    my $srv = FakeClamd->new(mode => 'ok');
    my $c   = ClamAV::Clamd->new(socket => $srv->path);

    is $c->scan(undef)->state, 'error', 'scan(undef) is refused';
    is $c->error_code, ClamAV::Clamd::ERR_CONFIG, '  as a config error';

    # Wide characters are not bytes. Guessing an encoding would mean
    # scanning something the caller never stored.
    my $wide = "\x{263A}";
    is $c->scan($wide)->state, 'error', 'wide characters are refused';
    like $c->error, qr/wide characters/, '  naming the problem';

    ok !$c->scan('')->is_error, 'an empty stream is allowed';
    $srv->stop;
}

# --- the local size guard ------------------------------------------------
{
    my $srv = FakeClamd->new(mode => 'ok');
    my $c   = ClamAV::Clamd->new(socket => $srv->path, max_size => 100);

    my $v = $c->scan('x' x 101);
    is $v->state, 'unscannable', 'max_size yields unscannable, not a bare error';
    is $v->reason, 'max_size', '  naming the local ceiling';
    ok !$v->is_clean, '  and certainly not clean';
    is $c->error_code, ClamAV::Clamd::ERR_TOOBIGLOCAL, '  the client records the refusal';

    ok !$c->scan('x' x 100)->is_error, 'a payload at the limit is allowed';
    $srv->stop;
}

# --- everything below needs a real clamd ---------------------------------
my $sock = $ENV{CLAMD_SOCKET};
unless ($sock) {
    for my $p (qw(
        /var/run/clamav/clamd.ctl  /run/clamav/clamd.ctl
        /var/run/clamav/clamd.sock /run/clamav/clamd.sock
        /tmp/clamd.socket
        /opt/homebrew/var/run/clamav/clamd.sock
        /usr/local/var/run/clamav/clamd.sock
    )) {
        next unless -S $p;
        next if length($p) >= ClamAV::Clamd::_sun_path_max();
        $sock = $p; last;
    }
}
unless ($sock) { done_testing; exit 0 }

my $c = ClamAV::Clamd->new(socket => $sock);
unless ($c->ping) { done_testing; exit 0 }

my $EICAR = 'X5O!P%@AP[4\PZX54(P^)7CC)7}' . '$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*';
is length($EICAR), 68, 'the EICAR fixture is the canonical 68 bytes';

is $c->scan($EICAR)->state, 'infected',   'scan() detects EICAR in memory';
is $c->scan('nothing here')->state, 'clean', 'scan() reports clean bytes clean';
is $c->transport, 'instream', 'scan() reports the instream transport';

# --- the transport actually used, and reported ---------------------------
{
    my $p = "$dir/e.txt";
    open my $fh, '>:raw', $p or die $!;
    print {$fh} $EICAR;
    close $fh;

    is $c->scan_path($p)->state, 'infected', 'scan_path over a UNIX socket works';
    is $c->transport, 'fildes', '  and used FILDES';

    my $t = ClamAV::Clamd->new(host => '127.0.0.1', port => 3310);
    my $r = $t->scan_path($p);
    SKIP: {
        skip 'no TCP clamd on 127.0.0.1:3310', 2 if $r->is_error;
        is $r->state, 'infected', 'scan_path over TCP falls back rather than failing';
        is $t->transport, 'instream', '  and reports the fallback transport';
    }
}

done_testing;
