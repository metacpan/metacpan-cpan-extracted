use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use File::Temp ();
use IO::Socket::UNIX ();
use Socket qw(SOCK_STREAM);
use ClamAV::Clamd;
use FakeClamd;

plan skip_all => 'needs UNIX sockets' unless ClamAV::Clamd::_sun_path_max();
plan skip_all => 'no descriptor passing on this platform'
    unless ClamAV::Clamd->have_fd_passing;

my $dir = File::Temp->newdir();

sub write_file {
    my ($name, $bytes) = @_;
    my $p = "$dir/$name";
    open my $fh, '>:raw', $p or die "open $p: $!";
    print {$fh} $bytes;
    close $fh;
    chmod 0600, $p;
    return $p;
}

# --- the handshake shape, without a clamd --------------------------------
# The command must go out ALONE, with the descriptor following in its own
# one-byte message. Sending them together is rejected by clamd with
# "ancillary data sent without FILDES", and it is the mistake every first
# implementation makes - including this one's.
{
    my $log = "$dir/handshake.log";
    my $srv = FakeClamd->new(mode => 'fildes', log => $log);
    my $c   = ClamAV::Clamd->new(socket => $srv->path);
    my $f   = write_file('probe.bin', 'harmless');

    my $r = $c->scan_path($f);
    ok defined $r, 'scan against the fd-passing fake returns a reply'
        or diag $c->error;

    $srv->stop;

    open my $fh, '<', $log or die "no handshake log: $!";
    chomp(my $line = <$fh>);
    close $fh;

    my @steps = split /\|/, $line;
    is $steps[0], 'zFILDES\0', 'the command goes out alone, z-framed';
    is $steps[1], '\0',        'the descriptor rides a separate one-byte message';
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

unless ($sock) {
    done_testing;
    exit 0;
}

my $c = ClamAV::Clamd->new(socket => $sock);
unless ($c->ping) {
    diag 'clamd socket present but not answering; skipping the live half';
    done_testing;
    exit 0;
}

my $EICAR = 'X5O!P%@AP[4\\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*';
my $eicar = write_file('eicar.txt', $EICAR);
my $clean = write_file('clean.txt', 'nothing to see here');

{
    my $v = $c->scan_path($eicar);
    is $v->state, 'infected', 'scan_path detects EICAR';
    is $v->signature, 'Eicar-Test-Signature', '  and names the signature';
    ok !$v->is_clean, '  is_clean is false';

    my $k = $c->scan_path($clean);
    is $k->state, 'clean', 'scan_path reports a clean file clean';
    ok $k->is_clean, '  is_clean is true';
    is $k->signature, undef, '  with no signature';
}

# --- the descriptor is BORROWED ------------------------------------------
{
    open my $fh, '<:raw', $eicar or die $!;
    my $before = tell $fh;
    is $c->scan_fd($fh)->state, 'infected', 'scan_fd takes a filehandle';
    ok fileno($fh) >= 0, '  the handle is still open afterwards';
    is tell($fh), $before, '  and its offset was not moved';
    close $fh;
}

{
    open my $fh, '<:raw', $clean or die $!;
    is $c->scan_fd(fileno $fh)->state, 'clean', 'scan_fd takes a raw descriptor number';
    close $fh;
}

# --- refusals ------------------------------------------------------------
{
    is $c->scan_path("$dir/no-such-file")->state, 'error', 'a missing path is an error verdict';
    is $c->error_code, ClamAV::Clamd::ERR_IO, '  reported as an IO error';

    opendir my $dh, $dir or die $!;
    is $c->scan_fd(fileno $dh)->state, 'error', 'a directory descriptor is refused';
    is $c->error_code, ClamAV::Clamd::ERR_NOTREG, '  reported as not-a-regular-file';
    closedir $dh;

    pipe(my $r, my $w) or die $!;
    is $c->scan_fd(fileno $r)->state, 'error', 'a pipe is refused';
    is $c->error_code, ClamAV::Clamd::ERR_NOTREG, '  also not-a-regular-file';
    close $r; close $w;

    is $c->scan_fd(undef)->state, 'error', 'a non-descriptor is refused';
    is $c->error_code, ClamAV::Clamd::ERR_CONFIG, '  reported as a config error';
}

# --- FILDES cannot cross a TCP socket ------------------------------------
# clamd does not say so: phase 0 measured that zFILDES over TCP produces
# no reply and no error and holds the connection open forever. The client
# must never send it there.
#
# Phase 2 refused outright. Phase 3 falls back to INSTREAM instead, which
# is correct but not free - the file now crosses the socket in full - so
# the transport is reported rather than silently substituted.
SKIP: {
    my $t = ClamAV::Clamd->new(host => '127.0.0.1', port => 3310);
    my $r = $t->scan_path($eicar);
    skip 'no TCP clamd on 127.0.0.1:3310', 3 if $r->is_error;

    is $r->state, 'infected',
        'a descriptor scan over TCP falls back and still gets a verdict';
    is $t->transport, 'instream', '  having used INSTREAM, not FILDES';
    isnt $t->transport, 'fildes',  '  which is the one thing it must not do';
}

# --- THE GATE ------------------------------------------------------------
# The whole justification for FILDES: clamd needs no permission on the
# path. Open the descriptor first, then make the path unreachable, then
# prove clamd's own path-based command fails on exactly the file our
# descriptor-based scan still reads.
SKIP: {
    skip 'running as root, which bypasses the permission check', 3 if $< == 0;

    my $vault = "$dir/vault";
    mkdir $vault or die "mkdir: $!";
    my $secret = "$vault/secret.bin";
    open my $w, '>:raw', $secret or die $!;
    print {$w} $EICAR;
    close $w;

    open my $fh, '<:raw', $secret or die $!;

    chmod 0000, $secret or die $!;
    chmod 0000, $vault  or die $!;

    ok !open(my $reopen, '<', $secret),
        'the path is unreachable even to us, who own it';

    my $by_path = do {
        my $s = IO::Socket::UNIX->new(Peer => $sock, Type => SOCK_STREAM);
        syswrite($s, "zSCAN $secret\0");
        sysread($s, my $b, 1024);
        $b =~ s/\0//g;
        $b;
    };
    like $by_path, qr/Permission denied/,
        "clamd's own path-based SCAN cannot read it";

    is $c->scan_fd($fh)->state, 'infected',
        'but the descriptor-based scan finds the signature anyway';

    chmod 0700, $vault; chmod 0600, $secret;
    close $fh;
}

done_testing;

