use strict;
use warnings;

use CSS::Struct::Output;
use File::Object;
use Test::More 'tests' => 3;
use Test::Output;
use Test::NoWarnings;

# Test.
my $obj = CSS::Struct::Output->new(
	'output_handler' => \*STDOUT,
);
my $right_ret = <<'END';
Selector
Definition
End of selector
END
chomp $right_ret;
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
	$right_ret,
);

# Test.
$obj = CSS::Struct::Output->new(
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
	$right_ret,
);
