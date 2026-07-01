use strict;
use warnings;
use Test::More;
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};
use Data::Intern::Shared;

# A child cannot fill 2M ids in 50ms; SIGKILL it mid-intern-storm and verify the
# parent can still acquire the write lock and intern (the dead-owner recovery).
my $in = Data::Intern::Shared->new(undef, 2_000_000, 64 << 20);
my $pid = fork // die $!;
if (!$pid) { $in->intern("s$_") for 1 .. 2_000_000; exit 0 }
select undef, undef, undef, 0.05;
kill 'KILL', $pid;
waitpid $pid, 0;

eval { $in->intern("after-the-crash") };
ok !$@, 'intern after child SIGKILL (write-lock recovery)';
ok defined($in->id_of("after-the-crash")), 'parent still interns after child SIGKILL';
ok defined $in->stats->{count}, 'stats reachable (lock not stranded)';

done_testing;
