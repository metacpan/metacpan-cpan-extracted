use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use Data::HashMap::Shared::SS;

# A refused store too big for even a packed arena must still trigger the slide:
# the holes it gathers serve every smaller size that has no free block of its
# own.

my $dir = tempdir(CLEANUP => 1);
my $m = Data::HashMap::Shared::SS->new("$dir/l.shm", 8192, 0, 0, 0, 65536);

# A full arena of 32-byte blocks with ten holes scattered through it.  The fill
# ends on a refused store; compact() while the arena is still dense disarms it,
# so the first slide attempted is the one the big store below asks for.
my $n = 0;
$n++ while $m->put(sprintf('k%05d', $n), 'x' x 20);
is $m->compact, 0, 'a dense arena gives a slide nothing to gather';
$m->remove(sprintf('k%05d', $_ * 97)) for 1 .. 10;

ok !$m->put('big', 'b' x 10_000), 'a store no packing can fit is refused';

my $stored = 0;
$stored += $m->put(sprintf('m%05d', $_), 'y' x 40) ? 1 : 0 for 1 .. 5;
is $stored, 5, 'and the slide it triggers still serves the 64-byte size, which no hole fits';

done_testing;
