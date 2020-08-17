use strict;
use warnings;

use CSS::Struct::Output::Indent;
use File::Object;
use Test::More 'tests' => 3;
use Test::Output;
use Test::NoWarnings;

# Test.
my $obj = CSS::Struct::Output::Indent->new(
	'output_handler' => \*STDOUT,
);
my $right_ret = <<'END';
selector {
	attr: value;
}
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
$obj = CSS::Struct::Output::Indent->new(
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
