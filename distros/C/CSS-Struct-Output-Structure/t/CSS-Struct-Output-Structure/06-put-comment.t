use strict;
use warnings;

use CSS::Struct::Output::Structure;
use IO::String;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = CSS::Struct::Output::Structure->new;
$obj->put(
	['c', 'comment #1', 'comment #2'],
);
my $ret_ar = $obj->flush;
is_deeply(
	$ret_ar,
	[
		['c', 'comment #1', 'comment #2'],
	],
	'Simple comment test (structure).',
);

# Test.
my $io_string = IO::String->new;
$obj = CSS::Struct::Output::Structure->new(
	'output_handler' => $io_string,
);
$obj->put(
	['c', 'comment #1', 'comment #2'],
);
$obj->flush;
is(${$io_string->string_ref}, "['c', 'comment #1', 'comment #2']\n",
	'Simple commmon test (handler).');
