use strict;
use warnings;

use CSS::Struct::Output::Structure;
use IO::String;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = CSS::Struct::Output::Structure->new;
$obj->put(
	['s', '.class'],
	['s', '#id'],
	['s', 'element'],
	['s', 'element.class'],
);
my $ret_ar = $obj->flush;
is_deeply(
	$ret_ar,
	[
		['s', '.class'],
		['s', '#id'],
		['s', 'element'],
		['s', 'element.class'],
	],
	'Simple selector test (structure).',
);

# Test.
my $io_string = IO::String->new;
$obj = CSS::Struct::Output::Structure->new(
	'output_handler' => $io_string,
);
$obj->put(
	['s', '.class'],
	['s', '#id'],
	['s', 'element'],
	['s', 'element.class'],
);
$obj->flush;
my $right_ret = <<'END';
['s', '.class']
['s', '#id']
['s', 'element']
['s', 'element.class']
END
is(${$io_string->string_ref}, $right_ret,
	'Simple selector test (handler).');
