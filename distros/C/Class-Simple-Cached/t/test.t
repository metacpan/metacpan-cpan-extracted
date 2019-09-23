#!perl -wT

use strict;
use warnings;
use Test::Most tests => 10;
use Test::NoWarnings;
use CHI;

BEGIN {
	use_ok('Class::Simple::Cached');
}

TEST: {
	my $cache = CHI->new(driver => 'RawMemory', datastore => {});
	$cache->on_set_error('die');
	$cache->on_get_error('die');
	my $l = new_ok('Class::Simple::Cached' => [ cache => $cache ]);

	ok($l->fred('wilma') eq 'wilma');
	ok($l->fred() eq 'wilma');
	ok($l->fred() eq 'wilma');

	my @rc = $l->adventure('plugh', 'xyzzy');
	ok(scalar(@rc) == 2);
	ok($rc[0] eq 'plugh');
	ok($rc[1] eq 'xyzzy');

	ok($cache->get('fred') eq 'wilma');

	# foreach my $key($cache->get_keys()) {
		# diag($key);
	# }
}
