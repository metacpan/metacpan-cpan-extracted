use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);

use Data::RingBuffer::Shared;

my $r = Data::RingBuffer::Shared::Int->new_memfd("mp", 16);

my $pid = fork // die;
if (!$pid) {
    my $r2 = Data::RingBuffer::Shared::Int->new_from_fd($r->memfd);
    $r2->write($_) for 1..10;
    _exit(0);
}
waitpid $pid, 0;

is $r->latest, 10, "latest after child writes";
is $r->latest(0), 10, "latest(0) = newest";
is $r->latest(9), 1, "latest(9) = oldest visible";

# Ring overflow
$r->write($_) for 11..30;
is $r->latest, 30, "latest after 30 writes";
# Oldest in a ring of 16: should be 15 or newer
cmp_ok $r->latest(15), '>=', 15, "oldest-visible is 15+ (overwritten earlier)";

done_testing;
