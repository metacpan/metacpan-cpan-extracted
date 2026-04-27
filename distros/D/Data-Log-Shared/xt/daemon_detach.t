use strict;
use warnings;
use Test::More;
use File::Temp qw(tmpnam);
use POSIX qw(setsid _exit);
use Data::Log::Shared;

plan skip_all => 'AUTHOR_TESTING not set' unless $ENV{AUTHOR_TESTING};

# Classic double-fork daemon: parent writes, child detaches (setsid +
# second fork), grandchild inherits mmap and appends. Parent reaps
# middle process immediately; grandchild is orphaned to init. Verify
# appended entries are readable when we reopen the file later.

my $path = tmpnam() . '.log';
my $log  = Data::Log::Shared->new($path, 4096);
$log->append("from parent");
my $base = $log->tail_offset;
undef $log;

my $pid = fork // die;
if ($pid == 0) {
    # middle process
    setsid();
    my $pid2 = fork // _exit(1);
    if ($pid2 != 0) { _exit(0); }   # middle exits; grandchild detaches
    # grandchild
    open STDOUT, '>', '/dev/null';
    open STDERR, '>', '/dev/null';
    my $l = Data::Log::Shared->new($path, 4096);
    $l->append("from daemon $$");
    $l->sync;
    undef $l;
    _exit(0);
}
waitpid($pid, 0);

# Give the grandchild time to finish
for (1..50) {
    last if -s $path > 200;   # rough — has at least 2 entries
    select(undef, undef, undef, 0.05);
}

# Parent reopens and reads
my $l = Data::Log::Shared->new($path, 4096);
my @entries;
my $off = 0;
while (my ($d, $next) = $l->read_entry($off)) {
    push @entries, $d;
    $off = $next;
}

is scalar(@entries), 2, 'two entries';
is $entries[0], 'from parent';
like $entries[1], qr/^from daemon \d+$/;

$l->unlink;
done_testing;
