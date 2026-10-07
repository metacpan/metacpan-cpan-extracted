use strict;
use warnings;
use Test::More;
use Time::HiRes qw(sleep setitimer ITIMER_REAL);
use POSIX ();
use File::Temp ();
use Data::HashMap::Shared::SS;

plan skip_all => 'AUTHOR_TESTING not set' unless $ENV{AUTHOR_TESTING};

# A writer is killed while a resize rehashes keys of 40 MB.  The process that
# recovers the lock finishes that resize under a fast signal timer: it must not
# be croaked with the lock held, so a third process can still write.
my $dir = File::Temp::tempdir(CLEANUP => 1);
my $mb = 40;
my @args = (1000, 0, 0, 0, (6 * $mb + 16) << 20);

sub rz_phase {
    open my $fh, '<:raw', $_[0] or die "open: $!";
    sysread $fh, my $hdr, 128;
    return unpack 'C', substr $hdr, 99, 1;
}

my $landed;
for my $delay (0.004, 0.002, 0.006, 0.001, 0.003) {
    my $path = "$dir/$delay.shm";
    pipe my $rd, my $wr or die;
    pipe my $go_rd, my $go_wr or die;
    my $writer = fork // die "fork: $!";
    unless ($writer) {
        close $rd; close $go_wr;
        my $m = Data::HashMap::Shared::SS->new($path, @args);
        $m->put(chr(64 + $_) x ($mb << 20), "v$_") or POSIX::_exit(1) for 1 .. 3;
        syswrite $wr, 'R';
        sysread $go_rd, my $go, 1;
        $m->reserve(500);
        POSIX::_exit(0);
    }
    close $wr; close $go_rd;
    sysread $rd, my $ready, 1 or die 'the writer could not fill the map';
    syswrite $go_wr, 'G';
    sleep $delay;
    kill 'KILL', $writer;
    waitpid $writer, 0;
    next unless rz_phase($path);
    $landed = 1;

    pipe my $res_rd, my $res_wr or die;
    pipe my $hold_rd, my $hold_wr or die;
    my $recoverer = fork // die "fork: $!";
    unless ($recoverer) {
        close $res_rd; close $hold_wr;
        my $m = Data::HashMap::Shared::SS->new($path, @args);
        local $SIG{ALRM} = sub { };
        setitimer(ITIMER_REAL, 20e-6, 20e-6);
        my $ok = eval { $m->put('small', 'x'); 1 };
        setitimer(ITIMER_REAL, 0, 0);
        syswrite $res_wr, $ok ? 'r' : 'c';
        sysread $hold_rd, my $done, 1;
        POSIX::_exit(0);
    }
    close $res_wr; close $hold_rd;
    sysread $res_rd, my $how, 1;
    my $probe = fork // die "fork: $!";
    unless ($probe) {
        alarm 5;
        my $m = Data::HashMap::Shared::SS->new($path, @args);
        POSIX::_exit($m->put('probe', 'y') ? 0 : 3);
    }
    waitpid $probe, 0;
    is $?, 0, "a third process writes while the recovering one lives (it " .
        ($how eq 'r' ? 'returned' : 'was croaked') . ')';
    close $hold_wr;
    waitpid $recoverer, 0;
    my $m = Data::HashMap::Shared::SS->new($path, @args);
    is $m->stat_recoveries, 1, 'the killed writer was recovered once';
    is scalar(grep { $m->exists(chr(64 + $_) x ($mb << 20)) } 1 .. 3), 3,
        'every entry survived the resize';
    last;
}
plan skip_all => 'no kill landed inside the resize' unless $landed;

done_testing;
