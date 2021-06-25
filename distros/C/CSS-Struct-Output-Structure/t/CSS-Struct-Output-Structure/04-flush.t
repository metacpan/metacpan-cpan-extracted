use strict;
use warnings;

use English qw(-no_match_vars);
use CSS::Struct::Output::Structure;
use Test::More 'tests' => 6;
use Test::NoWarnings;

# Test.
my $obj = CSS::Struct::Output::Structure->new;
my $ret_ar = $obj->flush;
is_deeply(
	$ret_ar,
	undef,
	'Get output from flush().',
);

# Test.
$obj = CSS::Struct::Output::Structure->new;
$obj->put(
	['c', 'comment'],
);
$ret_ar = $obj->flush;
is_deeply($ret_ar, [
	['c', 'comment'],
], 'First get of flush without reset.');
$ret_ar = $obj->flush;
is_deeply($ret_ar, [
	['c', 'comment'],
], 'Second get of flush without reset.');

# Test.
$obj = CSS::Struct::Output::Structure->new;
$obj->put(
	['c', 'comment'],
);
$ret_ar = $obj->flush(1);
is_deeply($ret_ar, [
	['c', 'comment'],
], 'First get of flush with reset.');
$ret_ar = $obj->flush;
is_deeply($ret_ar, undef, 'Second get of flush with reset.');
