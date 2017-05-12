use strict;
use warnings;

use Test::More tests => 4;

pass('a');
TODO:
{
	local $TODO = "TBD";
	fail('f');
	pass('p');
}
pass('c');

done_testing();
