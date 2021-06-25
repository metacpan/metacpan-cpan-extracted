use strict;
use warnings;

use CSS::Struct::Output::Structure;
use IO::String;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = CSS::Struct::Output::Structure->new;
$obj->put(
	['r', 'foo', 'bar'],
);
my $ret_ar = $obj->flush;
is_deeply(
	$ret_ar,
	[
		['r', 'foo', 'bar'],
	],
	'Simple raw test (structure).',
);

# Test.
my $io_string = IO::String->new;
$obj = CSS::Struct::Output::Structure->new(
	'output_handler' => $io_string,
);
$obj->put(
	['r', 'foo', 'bar'],
);
$obj->flush;
is(${$io_string->string_ref}, "['r', 'foo', 'bar']\n",
	'Simple raw test (handler).');
