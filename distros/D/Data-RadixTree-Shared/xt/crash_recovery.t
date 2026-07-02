use strict;
use warnings;
use Test::More;
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
use Data::RadixTree::Shared;

# A child cannot finish a 2M-insert storm in 50ms; SIGKILL it mid-storm while it
# may hold the write lock, then verify the parent can still take the write lock
# and insert -- the futex rwlock's dead-owner recovery. The anonymous MAP_SHARED
# mapping is inherited across fork.
#
# The storm reuses a BOUNDED set of 1000 keys ("k0".."k999"), so after the first
# pass every insert UPDATES an existing key and consumes no new node/arena space.
# 1000 keys use ~1003 of the 4096-node pool, so the child never croaks on pool
# exhaustion -- it only ever dies from the SIGKILL.
my $t = Data::RadixTree::Shared->new(undef, 4096, 65536);
my $pid = fork // die $!;
if (!$pid) { $t->insert("k" . ($_ % 1000), $_) for 1 .. 2_000_000; exit 0 }
select undef, undef, undef, 0.05;
kill 'KILL', $pid;
waitpid $pid, 0;

eval { $t->insert("after-the-crash", 42) };
ok !$@, 'insert after child SIGKILL (write-lock dead-owner recovery)';
ok defined($t->lookup("after-the-crash")), 'parent still inserts after child SIGKILL';
ok defined $t->stats->{keys}, 'stats reachable (lock not stranded)';

done_testing;
