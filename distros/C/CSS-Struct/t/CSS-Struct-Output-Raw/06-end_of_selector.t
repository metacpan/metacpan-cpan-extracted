use strict;
use warnings;

use CSS::Struct::Output::Raw;
use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 3;
use Test::NoWarnings;

# Test.
my $obj = CSS::Struct::Output::Raw->new;
eval {
	$obj->put(
		['e'],
	);
};
is($EVAL_ERROR, "No opened selector.\n");
clean();

# Test.
$obj->reset;
$obj->put(
	['s', 'body'],
	['e'],
);
my $ret = $obj->flush;
is($ret, 'body{}');
