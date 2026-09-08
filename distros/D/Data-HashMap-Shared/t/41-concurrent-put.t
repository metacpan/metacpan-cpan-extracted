use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use POSIX ();

use Data::HashMap::Shared::SS;

# A lost writer lock is invisible unless two put()s run at the same instant.
# Release N workers from a barrier onto disjoint key ranges, then check what an
# unlocked insert path cannot hold: hdr->size is a plain non-atomic ++ and the
# arena a plain bump pointer, so unlocked inserts lose counts, hand two writers
# the same arena bytes and drop keys, each surfacing as an arithmetic mismatch
# rather than a stall.  The table is pre-grown before the fork so no rehash
# overlaps the race and every failure is attributable.

# Real parallelism, not time-slicing, is what makes the unlocked window
# observable: on one CPU an unlocked put passes this test, so say so rather
# than report a false clean.
sub ncpu {
    return $ENV{TEST_NCPU} if $ENV{TEST_NCPU};
    if (open my $fh, '<', '/proc/self/status') {   # usable CPUs, not present ones
        while (<$fh>) {
            next unless /^Cpus_allowed_list:\s*(\S+)/;
            my $n = 0;
            for my $r (split /,/, $1) { $n += $r =~ /^(\d+)-(\d+)$/ ? $2 - $1 + 1 : 1 }
            return $n if $n;
        }
    }
    if (open my $fh, '<', '/proc/cpuinfo') {
        my $c = grep { /^processor\s*:/ } <$fh>;
        return $c if $c;
    }
    return 0;                       # unknown: run anyway
}
plan skip_all => 'needs 2+ CPUs to observe a lost writer lock' if ncpu() == 1;

my $WORKERS = 8;
my $PER     = 2000;
my $TOTAL   = $WORKERS * $PER;

sub val_for { "v:$_[0]:" . ('p' x 24) }   # >7 bytes: forces an arena allocation

my $dir  = tempdir(CLEANUP => 1);   # survives a die: no stray 10MB file
my $path = "$dir/putrace.shm";
my $map  = Data::HashMap::Shared::SS->new($path, $TOTAL * 4);
$map->reserve($TOTAL * 2);                # settle table_cap before anyone writes
my $cap0 = $map->capacity;

pipe(my $rd, my $wr) or die "pipe: $!";

my @pids;
for my $w (0 .. $WORKERS - 1) {
    my $pid = fork;
    die "fork: $!" unless defined $pid;
    if ($pid == 0) {
        close $wr;
        alarm 15;                        # a wedged worker fails the test, never hangs it
        my $child = Data::HashMap::Shared::SS->new($path, $TOTAL * 4);
        my $go;
        sysread($rd, $go, 1);            # barrier: every worker starts together
        my $refused = 0;
        for my $i (0 .. $PER - 1) {
            my $k = "w$w-k$i";
            $refused++ unless $child->put($k, val_for($k));
        }
        POSIX::_exit($refused ? 1 : 0);
    }
    push @pids, $pid;
}
close $rd;

local $SIG{ALRM} = sub {
    kill 'KILL', @pids;
    die "concurrent put probe exceeded its time budget\n";
};
alarm 60;

syswrite($wr, 'g' x $WORKERS) == $WORKERS or die "barrier release: $!";
close $wr;

my ($crashed, $refused) = (0, 0);
for my $pid (@pids) {
    waitpid($pid, 0);
    if    ($? & 127) { $crashed++ }
    elsif ($? >> 8)  { $refused++ }
}
alarm 0;

is($crashed, 0, "no worker died on a signal");
is($refused, 0, "no worker had a put refused");
is($map->capacity, $cap0, "the pre-grown table never rehashed under the race");

my @live = $map->keys;
is(scalar @live, $map->size,
   sprintf "the live slot count agrees with size() (%d vs %d)",
           scalar @live, $map->size);
is($map->size, $TOTAL, "size() is exactly the $TOTAL distinct keys stored");

my ($missing, $wrong) = (0, 0);
for my $w (0 .. $WORKERS - 1) {
    for my $i (0 .. $PER - 1) {
        my $k = "w$w-k$i";
        my $v = $map->get($k);
        if    (!defined $v)       { $missing++ }
        elsif ($v ne val_for($k)) { $wrong++ }
    }
}
is($missing, 0, "every key stored by a worker is still readable");
is($wrong,   0, "every value reads back exactly as its writer stored it");

done_testing;
