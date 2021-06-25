use strict;
use warnings;

use CSS::Struct::Output::Structure;
use IO::String;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = CSS::Struct::Output::Structure->new;
$obj->put(
	['e'],
);
my $ret_ar = $obj->flush;
is_deeply(
	$ret_ar,
	[
		['e'],
	],
	'Simple end of selector test (structure).',
);

# Test.
my $io_string = IO::String->new;
$obj = CSS::Struct::Output::Structure->new(
	'output_handler' => $io_string,
);
$obj->put(
	['e'],
);
$obj->flush;
is(${$io_string->string_ref}, "['e']\n",
	'Simple end of selector test (handler).');
