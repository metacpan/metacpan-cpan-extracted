use strict;
use warnings;

use Test::More tests => 10;

for (1 .. 10)
{
	pass("$_ ($0)");
}

done_testing();
