use strict; use warnings; use Test::More;
use Data::SpatialHash::Shared;
use POSIX ();

my $s = Data::SpatialHash::Shared->new(undef, 100, 0, 1.0);

# no eventfd until requested
is $s->fileno, -1, 'fileno is -1 before any eventfd';
is $s->eventfd_consume, undef, 'eventfd_consume undef with no eventfd';

# lazy create + idempotent
my $fd = $s->eventfd;
cmp_ok $fd, '>=', 0, 'eventfd creates and returns a valid fd';
is $s->fileno, $fd, 'fileno returns the eventfd';
is $s->eventfd, $fd, 'eventfd is idempotent (same fd)';

# notify accumulates; eventfd_consume reads and resets
ok $s->notify, 'notify writes';
ok $s->notify, 'notify again';
is $s->eventfd_consume, 2, 'eventfd_consume reads accumulated count (2)';
is $s->eventfd_consume, undef, 'eventfd_consume undef when nothing pending';

# eventfd_set swaps in an external fd (closing the previously-owned one)
open my $devnull, '>', '/dev/null' or die "open /dev/null: $!";
my $extfd = POSIX::dup(fileno $devnull);
cmp_ok $extfd, '>=', 0, 'dup an external fd';
$s->eventfd_set($extfd);
is $s->fileno, $extfd, 'eventfd_set swaps in the external fd';
# $s now owns $extfd and closes it on DESTROY; $devnull stays ours
close $devnull;

done_testing;
