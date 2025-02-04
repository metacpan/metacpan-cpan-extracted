#! perl

use strict;
use warnings;

use Test::More;

use Crypt::SysRandom::XS 'random_bytes';

my $first = random_bytes(16);

is length $first, 16, '$first is 16 bytes';
isnt $first, scalar("\0" x 16), "\$first isn't empty";

my $second = random_bytes(16);

isnt $first, $second, "\$first isn't second";

done_testing;
