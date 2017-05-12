#!perl
use strict;
use Test::More tests => 2;

BEGIN
{
	use_ok('DateTime::Util::Calc', 'search_next', 'binary_search');
}

my $rv = search_next(
	base  => 1,
	check => sub { $_[0] % 19 == 0 },
	next  => sub { $_[0] + 3 }
);
ok($rv == 19);

# TODO: think of good tests for binary_search
