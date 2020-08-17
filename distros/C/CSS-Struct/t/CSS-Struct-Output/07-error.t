use strict;
use warnings;

use CSS::Struct::Output;
use English qw(-no_match_vars);
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $obj = CSS::Struct::Output->new;
eval {
	$obj->put('String');
};
is($EVAL_ERROR, "Bad data.\n");
clean();

# Test.
eval {
	$obj->put(
		['s'],
	);
};
is($EVAL_ERROR, "Bad number of arguments.\n");
clean();

# Test.
$obj->reset;
eval {
	$obj->put(
		['s', 'selector', 'bad_selector'],
	);
};
is($EVAL_ERROR, "Bad number of arguments.\n");
clean();

# Test.
$obj = CSS::Struct::Output->new(
	'skip_bad_types' => 0,
);
eval {
	$obj->put(
		['q', 'bad data'],
	);
};
is($EVAL_ERROR, "Bad type of data.\n");
clean();
