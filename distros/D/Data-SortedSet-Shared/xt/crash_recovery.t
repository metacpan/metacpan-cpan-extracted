use strict;
use warnings;
use Test::More;
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
use Data::SortedSet::Shared;

# A 1M-entry set the child cannot fill in 50ms; SIGKILL it mid-add-storm and
# verify the parent can still acquire the write lock and operate (the dead-owner
# recovery path), with the tree left in a consistent state.
my $z = Data::SortedSet::Shared->new(undef, 1_000_000);
my $pid = fork // die $!;
if (!$pid) { $z->add($_, rand()) for 1 .. 1_000_000; exit 0; }
select undef, undef, undef, 0.05;     # let it run into the add storm
kill 'KILL', $pid;
waitpid $pid, 0;

eval { $z->clear };
ok !$@, 'clear after child SIGKILL (write-lock recovery)';
ok defined($z->add(42, 1.5)), 'parent still adds after child SIGKILL';
ok defined $z->stats->{count}, 'stats reachable (lock not stranded)';
ok $z->_validate, 'tree consistent after recovery';

done_testing;
