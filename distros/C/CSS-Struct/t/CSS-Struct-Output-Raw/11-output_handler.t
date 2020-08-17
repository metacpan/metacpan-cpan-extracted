use strict;
use warnings;

use CSS::Struct::Output::Raw;
use File::Object;
use Test::More 'tests' => 3;
use Test::Output;
use Test::NoWarnings;

# Test.
my $obj = CSS::Struct::Output::Raw->new(
	'output_handler' => \*STDOUT,
);
stdout_is(
	sub {
		$obj->put(
			['s', 'selector'],
			['d', 'attr', 'value'],
			['e'],
		);
		$obj->flush;
		return;
	},
	'selector{attr:value;}',
);

# Test.
$obj = CSS::Struct::Output::Raw->new(
	'auto_flush' => 1,
	'output_handler' => \*STDOUT,
);
stdout_is(
	sub {
		$obj->put(
			['s', 'selector'],
			['d', 'attr', 'value'],
			['e'],
		);
		return;
	},
	'selector{attr:value;}',
);
