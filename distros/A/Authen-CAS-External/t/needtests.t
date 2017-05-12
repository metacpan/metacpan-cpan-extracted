#!perl -T

use Test::More tests => 1;

TODO: {
	local $TODO = q{Need to write tests!};
	is('tests made?', 'nope', 'see if tests are made');
}
