use strict;
use warnings;

use CSS::Struct::Output::Structure;
use IO::String;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = CSS::Struct::Output::Structure->new;
$obj->put(
	['a', '@charset', 'utf-8'],
);
my $ret_ar = $obj->flush;
is_deeply(
	$ret_ar,
	[
		['a', '@charset', 'utf-8'],
	],
	'Simple at-rule test (structure).',
);

# Test.
my $io_string = IO::String->new;
$obj = CSS::Struct::Output::Structure->new(
	'output_handler' => $io_string,
);
$obj->put(
	['a', '@charset', 'utf-8'],
);
$obj->flush;
is(${$io_string->string_ref}, "['a', '\@charset', 'utf-8']\n",
	'Simple at-rule test (handler).');
