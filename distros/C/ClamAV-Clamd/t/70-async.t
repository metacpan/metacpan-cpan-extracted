use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use File::Temp ();
use IO::Select ();
use ClamAV::Clamd;
use FakeClamd;

plan skip_all => 'needs UNIX sockets' unless ClamAV::Clamd::_sun_path_max();

my $dir = File::Temp->newdir();

# A loop. Not an adapter, not a dependency, not a framework - twelve
# lines of select(), which is the entire claim this phase makes: any
# loop can drive this, and none of them are the dist's problem.
sub drive {
    my (@scans) = @_;
    my $steps = 0;
    my $guard = 0;
    while (grep { !$_->is_done } @scans) {
        die "drive() ran away" if ++$guard > 100_000;
        for my $s (grep { !$_->is_done } @scans) {
            my $fd   = $s->fd;
            my $want = $s->want // '';
            if (defined $fd && $want) {
                my $set = IO::Select->new($fd);
                $want eq 'read'
                    ? IO::Select->select($set, undef, undef, 0.5)
                    : IO::Select->select(undef, $set, undef, 0.5);
            }
            $s->step;
            $steps++;
        }
    }
    return $steps;
}

# --- the surface --------------------------------------------------------
{
    my $srv = FakeClamd->new(mode => 'literal', literal => 'stream: OK');
    my $c   = ClamAV::Clamd->new(socket => $srv->path, reply_timeout => 10);
    my $s   = $c->start_scan('some bytes');

    isa_ok $s, 'ClamAV::Clamd::Scan', 'start_scan returns a handle';
    ok defined $s->fd, 'it has a descriptor to register';
    like $s->want, qr/^(read|write)$/, 'and a readiness to wait for';
    ok !$s->is_done, 'it is not finished yet';
    is $s->verdict, undef, 'and has no verdict yet - asking early has no answer';

    drive($s);

    ok $s->is_done, 'it finishes';
    is $s->fd, undef, '  and stops offering a descriptor to watch';
    is $s->want, undef, '  and wants nothing';
    is $s->verdict->state, 'clean', '  and now has a verdict';
    $srv->stop;
}

# --- a step that cannot progress must not spin --------------------------
# On a level-triggered loop the caller calls straight back. A machine
# that returns "not finished" without consuming or producing anything
# would pin a core while looking like it was working.
{
    my $srv = FakeClamd->new(mode => 'stall');
    my $c   = ClamAV::Clamd->new(socket => $srv->path, reply_timeout => 60);
    my $s   = $c->start_scan('x');

    my $steps = 0;
    $steps++ until $s->step or $steps > 200_000;   # no waiting at all

    ok $s->is_done, 'a scan stepped without readiness terminates';
    cmp_ok $steps, '<', 200_000, '  rather than spinning forever';
    ok !$s->verdict->is_clean, '  and does not report clean';
    $srv->stop;
}

# --- cancellation -------------------------------------------------------
# The connection must be CLOSED, never kept. clamd is still going to
# answer, and a connection carrying an unread verdict would hand it to
# whichever scan picked that connection up next.
{
    my $srv = FakeClamd->new(mode => 'stall');
    my $c   = ClamAV::Clamd->new(socket => $srv->path, reply_timeout => 60);
    my $s   = $c->start_scan('x');

    ok defined $s->fd, 'a live scan has a descriptor';
    $s->cancel;
    ok $s->is_done, 'cancel finishes the scan';
    is $s->fd, undef, '  and gives up the descriptor';
    ok !$s->verdict->is_clean, '  a cancelled scan is not clean';
    $srv->stop;
}

# --- dropping a handle mid-flight must not leak or crash ----------------
{
    my $srv = FakeClamd->new(mode => 'stall');
    my $c   = ClamAV::Clamd->new(socket => $srv->path, reply_timeout => 60);
    for (1 .. 20) {
        my $s = $c->start_scan('x');
        ok $s->fd, 'started' if $_ == 1;
        # $s goes out of scope un-stepped; DESTROY must close it
    }
    pass 'twenty handles dropped in flight without stepping';
    $srv->stop;
}

# --- everything below wants a real clamd --------------------------------
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

sub write_file {
    my ($n, $b) = @_;
    my $p = "$dir/$n";
    open my $fh, '>:raw', $p or die $!;
    print {$fh} $b;
    close $fh;
    return $p;
}
my $eicar = write_file('e.txt', $EICAR);
my $clean = write_file('c.txt', 'nothing to see');

# --- THE GATE -----------------------------------------------------------
# The same scan, driven three ways, must give the same verdict. If the
# blocking and non-blocking paths can disagree then one of them is a
# second implementation of the protocol, which is exactly what this phase
# exists to prevent.
for my $case ([$eicar, 'infected'], [$clean, 'clean']) {
    my ($path, $want) = @$case;
    my $name = $path =~ /e\.txt/ ? 'eicar' : 'clean';

    my $blocking = $c->scan_path($path);
    is $blocking->state, $want, "$name: blocking gives $want";

    my $async = $c->start_scan($path, 'path');
    drive($async);
    is $async->verdict->state, $want, "$name: driven under select gives $want";
    is $async->verdict->signature, $blocking->signature,
        "$name: and the same signature";
}

# --- interleaved, in one process ----------------------------------------
# Two scans in flight at once, stepped alternately. Nothing may leak from
# one connection into the other - the failure this would show up as is a
# scan reporting the OTHER scan's verdict.
{
    my @scans = (
        $c->start_scan($eicar, 'path'),
        $c->start_scan($clean, 'path'),
        $c->start_scan($EICAR),
        $c->start_scan('harmless bytes'),
    );
    drive(@scans);

    is $scans[0]->verdict->state, 'infected', 'interleaved scan 1: infected';
    is $scans[1]->verdict->state, 'clean',    'interleaved scan 2: clean';
    is $scans[2]->verdict->state, 'infected', 'interleaved scan 3: infected';
    is $scans[3]->verdict->state, 'clean',    'interleaved scan 4: clean';
}

# --- a filehandle scan holds its source alive ---------------------------
# The handle keeps a reference, because the scan outlives the call that
# started it and reading a freed PV is not a bug that shows up locally.
{
    my $s = do {
        open my $fh, '<:raw', $eicar or die $!;
        $c->start_scan($fh, 'fd');
    };                                   # $fh out of scope, scan still live
    drive($s);
    is $s->verdict->state, 'infected', 'a scan outlives the handle it was given';
}

{
    my $s = do {
        my $bytes = $EICAR;
        $c->start_scan($bytes);
    };                                   # $bytes out of scope
    drive($s);
    is $s->verdict->state, 'infected', 'a byte scan outlives the scalar it was given';
}

done_testing;
