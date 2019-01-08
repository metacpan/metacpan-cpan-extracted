#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

use Data::LNPath qw/path/, { as => { path => 'lnpath' }, return_undef => 1 };

my $data = {
	one => {
		a => [qw/10 2 3/],
		b => { a => 10, b => 1, c => 1 },
		c => 1
	},
	two => [qw/1 2 3/],
	three => 0,
	four => sub { return 'test' },
};

is(path($data, '/three'), 0, 'three');
is(path($data, '/ten'), undef, 'ten');
is(path($data, '/four/five')->(), 'test', 'code reference');

is(path(undef, undef), undef, 'code reference');


done_testing();

