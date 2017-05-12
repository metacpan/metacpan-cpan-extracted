use strict;
use warnings;

use Test::More tests => 5;

for (1 .. 5)
{
	pass("$_ $0");
	sleep(1);
}

done_testing();
