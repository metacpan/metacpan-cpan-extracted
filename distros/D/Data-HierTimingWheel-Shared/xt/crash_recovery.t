use strict;
use warnings;
use Test::More;
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
use Data::HierTimingWheel::Shared;

# A child cannot finish scheduling+cancelling 2M timers in 50ms; SIGKILL it
# mid-storm while it may hold the write lock, then verify the parent can still
# take the write lock and schedule -- the futex rwlock's dead-owner recovery.
# The anonymous MAP_SHARED mapping is inherited across fork, so parent and child
# contend on the one wheel.
my $h = Data::HierTimingWheel::Shared->new(undef, 64, 4, 100_000);
my $pid = fork // die $!;
if (!$pid) {
    my $s = 1;
    for (1 .. 2_000_000) {
        $s = ($s * 1103515245 + 12345) & 0x7fffffff;
        my $id = $h->add(1 + $s % 200000, $s);   # delays spanning several levels
        $h->cancel($id) if $s % 2;
    }
    exit 0;
}
select undef, undef, undef, 0.05;   # 50ms
kill 'KILL', $pid;
waitpid $pid, 0;

my $id = eval { $h->add(1, 424242) };
ok !$@, 'schedule after child SIGKILL (write-lock dead-owner recovery)';
ok defined($h->stats->{count}), 'stats reachable (lock not stranded)';
# advancing must still fire the timer we just added, proving the lists are usable
my %got;
$got{$_} = 1 for $h->advance(1);
ok $got{424242}, 'the post-crash timer fires (bucket + free lists intact)';

done_testing;
