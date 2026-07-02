use strict; use warnings; use Test::More;
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
use Data::SpatialHash::Shared;
# 1M-entry hash so the child cannot fill it in 50ms
my $s = Data::SpatialHash::Shared->new(undef, 1_000_000, 0, 1.0);
# child grabs the write lock by starting a long insert loop then is SIGKILLed.
# We cannot easily freeze mid-critical-section from Perl, so instead assert the
# timeout-recovery path is reachable: kill a child mid-insert-storm and verify
# the parent can still acquire the lock and operate.
my $pid = fork // die $!;
if (!$pid) { $s->insert(rand(), rand(), $_) for 1..1_000_000; exit 0; }
select undef, undef, undef, 0.05;     # let it run
kill 'KILL', $pid; waitpid $pid, 0;
# clear to make room (also exercises lock acquisition after child SIGKILL)
eval { $s->clear };
ok !$@, 'clear after child SIGKILL (lock recovery)';
ok defined($s->insert(1,1,42)), 'parent still inserts after child SIGKILL';
ok defined $s->stats->{count}, 'stats reachable (lock not stranded)';
done_testing;
