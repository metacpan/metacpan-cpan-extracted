use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Time::HiRes qw(sleep);
use POSIX ();
use IO::Pipe;

use Data::HashMap::Shared::SS;

# Kill a compacting writer at a random point, over and over, and read the map
# back from a fresh process: a partly compacted arena must still serve every
# entry, and the stale write lock the kill leaves behind must recover.
#
# This does not establish the crash-safety rule itself.  The window between
# copying a block and publishing its new offset is nanoseconds wide, so a random
# kill effectively never lands in it -- a build with the rule removed passes this
# test unchanged.  xt/compact_crash_gdb.t stops exactly there instead.

plan skip_all => 'author tests' unless $ENV{AUTHOR_TESTING};

my $dir   = tempdir(CLEANUP => 1);
my $path  = "$dir/compact.shm";
# Sized to stay small on a tight machine: the kill window is measured from one
# real compaction below, so fewer entries cost trials, not validity.
my $N     = 15_000;
my $TRIALS = 25;

my $m = Data::HashMap::Shared::SS->new($path, 2 * $N, 0, 0, 0, 12 * 1024 * 1024);
my $key = sub { sprintf 'key%017d', $_[0] };           # 20 bytes: never inline

sub value_for {
    my ($i, $round) = @_;
    my $c = ($i + $round) % 2 ? 'a' : 'b';       # a bare (...) x N here would repeat the LIST
    # Spans three size classes (256/512/1024), so a rewrite frees a block the
    # new value cannot use and the arena really fragments.
    return $c x (150 + (($i + $round) % 3) * 200);
}
# fragment() rewrites only the even entries, so the odd ones still hold round 0.
sub expected { my ($i, $round) = @_; return value_for($i, $i % 2 ? 0 : $round) }

for my $i (0 .. $N - 1) {
    $m->put($key->($i), value_for($i, 0))
        or BAIL_OUT("could not build the fixture at entry $i (arena too small)");
}
is $m->size, $N, "fixture holds $N entries";

# Time one uninterrupted compaction, so the kill window is scaled to this
# machine rather than to mine.
fragment(0);
my $t0 = Time::HiRes::time();
my $reclaimed = $m->compact;
my $window = Time::HiRes::time() - $t0;
cmp_ok $reclaimed, '>', 0, 'a fragmented arena has something to reclaim';
note sprintf 'one compaction: %.1f ms, %d bytes reclaimed', $window * 1000, $reclaimed;
$window = 0.005 if $window < 0.005;

sub fragment {                    # rewrite every value into a different class
    my ($round) = @_;
    for (my $i = 0; $i < $N; $i += 2) {
        $m->put($key->($i), value_for($i, $round));
    }
}

sub check_from_fresh_process {    # returns '' when consistent, else what broke
    my ($round) = @_;
    my $pipe = IO::Pipe->new;
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        $pipe->writer;
        $SIG{ALRM} = 'DEFAULT'; alarm 60;
        my $bad = eval {
            my $c = Data::HashMap::Shared::SS->new($path, 2 * $N, 0, 0, 0, 12 * 1024 * 1024);
            my $wrong = 0;
            my $missing = 0;
            for my $i (0 .. $N - 1) {
                my $got = $c->get($key->($i));
                if (!defined $got)                        { $missing++ }
                elsif ($got ne expected($i, $round))       { $wrong++ }
            }
            "wrong=$wrong missing=$missing size=" . $c->size;
        } // "died: $@";
        print {$pipe} "$bad\n";
        $pipe->close;
        POSIX::_exit(0);
    }
    $pipe->reader;
    my $line = <$pipe>;
    $pipe->close;
    waitpid $pid, 0;
    return 'the checker was killed by signal ' . ($? & 127) if ($? & 127);
    chomp($line //= 'no answer from the checker');
    return $line;
}

my ($interrupted, $clean) = (0, 0);
for my $round (1 .. $TRIALS) {
    fragment($round);
    my $before = $m->arena_used;

    my $pipe = IO::Pipe->new;
    my $pid = fork // die "fork: $!";
    if (!$pid) {
        $pipe->writer;
        my $c = Data::HashMap::Shared::SS->new($path, 2 * $N, 0, 0, 0, 12 * 1024 * 1024);
        print {$pipe} "go\n";
        $pipe->close;
        $c->compact;
        POSIX::_exit(0);
    }
    $pipe->reader;
    <$pipe>;
    $pipe->close;
    sleep rand($window * 1.3);
    my $killed = kill 9, $pid;
    waitpid $pid, 0;
    my $by_signal = ($? & 127) == 9;
    $by_signal ? $interrupted++ : $clean++;

    my $state = check_from_fresh_process($round);
    like $state, qr/^wrong=0 missing=0 size=$N$/,
        "trial $round: the map is intact after a" . ($by_signal ? ' killed' : ' completed') . ' compaction'
        or diag "before=$before state=$state killed=$killed";
}

note "killed mid-compaction: $interrupted, completed first: $clean";
cmp_ok $interrupted, '>', 0, 'at least one compaction really was interrupted'
    or diag 'the kill window never landed inside a compaction: this run proved little';

done_testing;
