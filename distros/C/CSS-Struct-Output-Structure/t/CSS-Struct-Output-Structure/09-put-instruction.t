use strict;
use warnings;

use CSS::Struct::Output::Structure;
use IO::String;
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = CSS::Struct::Output::Structure->new;
$obj->put(
	['i', 'target', 'code'],
);
my $ret_ar = $obj->flush;
is_deeply(
	$ret_ar,
	[
		['i', 'target', 'code'],
	],
	'Simple instruction test (structure).',
);

# Test.
my $io_string = IO::String->new;
$obj = CSS::Struct::Output::Structure->new(
	'output_handler' => $io_string,
);
$obj->put(
	['i', 'target', 'code'],
);
$obj->flush;
is(${$io_string->string_ref}, "['i', 'target', 'code']\n",
	'Simple instruction test (handler).');
