use strict;
use warnings;

use Test::More tests => 4;

	pass('a');
	SKIP:
	{
		skip("broken", 2);
		fail('b1'); # will be skipped
		pass('b2'); # will be skipped
	}
	pass('c');

done_testing();
