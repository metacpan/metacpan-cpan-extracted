use strict;
use warnings;

use CSS::Struct::Output::Structure;
use IO::String;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = CSS::Struct::Output::Structure->new;
$obj->put(
	['d', 'background-color', 'red'],
);
my $ret_ar = $obj->flush;
is_deeply(
	$ret_ar,
	[
		['d', 'background-color', 'red'],
	],
	'Simple definition test (structure).',
);

# Test.
my $io_string = IO::String->new;
$obj = CSS::Struct::Output::Structure->new(
	'output_handler' => $io_string,
);
$obj->put(
	['d', 'background-color', 'red'],
);
$obj->flush;
is(${$io_string->string_ref}, "['d', 'background-color', 'red']\n",
	'Simple definition test (handler).');
