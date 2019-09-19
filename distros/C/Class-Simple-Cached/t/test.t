#!perl -wT

use strict;
use warnings;
use Test::Most tests => 6;
use Test::NoWarnings;
use CHI;

BEGIN {
	use_ok('Class::Simple::Cached');
}

TEST: {
	my $cache = CHI->new(driver => 'RawMemory', global => 1);
	$cache->on_set_error('die');
	$cache->on_get_error('die');
	my $l = new_ok('Class::Simple::Cached' => [ cache => $cache ]);

	ok($l->fred('wilma') eq 'wilma');
	ok($l->fred() eq 'wilma');
	ok($l->fred() eq 'wilma');

	# foreach my $key($cache->get_keys()) {
		# diag($key);
	# }
}
