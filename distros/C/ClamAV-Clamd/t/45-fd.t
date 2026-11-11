use strict;
use warnings;
use FindBin ();
use lib "$FindBin::Bin/lib";
use Test::More;
use File::Temp ();
use ClamAV::Clamd;
use FakeClamd;

# Descriptor and path scans against the fake, over a UNIX socket where the
# descriptor itself travels and over TCP where the file has to be streamed.

plan skip_all => 'needs UNIX sockets' unless ClamAV::Clamd::_sun_path_max();

my $dir = File::Temp->newdir();

sub write_file {
    my ($name, $bytes) = @_;
    my $p = "$dir/$name";
    open my $fh, '>:raw', $p or die "open $p: $!";
    print {$fh} $bytes;
    close $fh;
    return $p;
}

my $small = write_file('small.bin', 'harmless');
my $big   = write_file('big.bin', 'y' x 100_000);

# --- what scan_fd takes --------------------------------------------------------
{
    my $srv = FakeClamd->new(mode => 'ok');
    my $c   = ClamAV::Clamd->new(socket => $srv->path);
    my $want = ClamAV::Clamd->have_fd_passing ? 'fildes' : 'instream';

    open my $fh, '<:raw', $small or die $!;
    is $c->scan_fd($fh)->state, 'clean', 'a lexical filehandle';
    is $c->transport, $want, "  over $want";
    is $c->scan_fd(fileno $fh)->state, 'clean', 'a descriptor number';
    is $c->scan_fd('' . fileno $fh)->state, 'clean', 'a descriptor number as a string';
    is $c->scan_fd(\*STDIN)->state, 'error', 'a glob reference to something that is not a file';
    is $c->error_code, ClamAV::Clamd::ERR_NOTREG, '  is refused as not a regular file';
    is $c->scan_fd(*STDIN)->state, 'error', 'a bare glob too';
    is $c->error_code, ClamAV::Clamd::ERR_NOTREG, '  for the same reason';

    my $n = fileno $fh;
    close $fh;
    is $c->scan_fd($fh)->state, 'error', 'a closed filehandle';
    is $c->error_code, ClamAV::Clamd::ERR_CONFIG, '  is a config error';
    is $c->scan_fd($n)->state, 'error', 'the number it had';
    is $c->error_code, ClamAV::Clamd::ERR_IO, '  cannot be stat-ed';
    like $c->error, qr/fstat/, '  and says so';

    for my $bad (['abc', 'a word'], [-1, 'a negative number'], [2**31, 'a number too large for a descriptor']) {
        is $c->scan_fd($bad->[0])->state, 'error', "$bad->[1] is refused";
        is $c->error_code, ClamAV::Clamd::ERR_CONFIG, '  as a config error';
    }

    pipe(my $r, my $w) or die $!;
    is $c->scan_fd($r)->state, 'error', 'a pipe is refused';
    is $c->error_code, ClamAV::Clamd::ERR_NOTREG, '  as not a regular file';
    close $r; close $w;

    opendir my $dh, $dir or die $!;
    SKIP: {
        my $dfd = fileno $dh;
        skip 'fileno on a directory handle needs perl 5.22', 2
            unless defined $dfd && $dfd >= 0;
        is $c->scan_fd($dfd)->state, 'error', 'a directory descriptor is refused';
        is $c->error_code, ClamAV::Clamd::ERR_NOTREG, '  as not a regular file';
    }
    closedir $dh;

    $srv->stop;
}

# --- paths ------------------------------------------------------------------------
{
    my $srv = FakeClamd->new(mode => 'ok');
    my $c   = ClamAV::Clamd->new(socket => $srv->path);
    is $c->scan_path($small)->state, 'clean', 'a path';
    is $c->scan_path("$dir/no-such-file")->state, 'error', 'a missing path is an error verdict';
    is $c->error_code, ClamAV::Clamd::ERR_IO, '  reported as an IO error';
    like $c->error, qr/open/, '  from the open';
    is $c->transport, undef, '  with no transport';

    my $m = ClamAV::Clamd->new(socket => $srv->path, max_size => 10);
    my $v = $m->scan_path($big);
    is $v->state, 'unscannable', 'a file over max_size is unscannable';
    is $v->reason, 'max_size', '  naming the local ceiling';
    is $m->error_code, ClamAV::Clamd::ERR_TOOBIGLOCAL, '  and the client records the refusal';
    is $m->scan_path($small)->state, 'clean', '  while one under it scans';
    $srv->stop;

    my $dead = ClamAV::Clamd->new(socket => '/tmp/cc-no-clamd-here.sock');
    is $dead->scan_path($small)->state, 'error', 'a path scan with nothing listening';
    is $dead->error_code, ClamAV::Clamd::ERR_CONNECT, '  is a connect error';
}

# --- over TCP the file crosses the socket ----------------------------------------
{
    my $srv = FakeClamd->new(mode => 'ok', tcp => 1);
    my $c   = ClamAV::Clamd->new($srv->target, chunk => 4096);
    is $c->scan_path($big)->state, 'clean', 'a path over TCP';
    is $c->transport, 'instream', '  is streamed';
    open my $fh, '<:raw', $big or die $!;
    is $c->scan_fd($fh)->state, 'clean', 'a descriptor over TCP';
    is $c->transport, 'instream', '  is streamed too';
    close $fh;
    $srv->stop;
}

done_testing;
