#!perl -wT

use strict;
use warnings;
use Class::Simple::Readonly::Cached;
use CHI;
use Test::Most;

eval 'use Test::Carp';

CARP: {
	if($@) {
		plan(skip_all => 'Test::Carp needed to check error messages');
	} else {
		does_carp_that_matches(sub {
			Class::Simple::Readonly::Cached->new()
		}, qr/^Usage:\s/);

		does_carp_that_matches(sub {
			Class::Simple::Readonly::Cached->new({ foo => 'bar' })
		}, qr/^Usage:\s/);

		does_carp_that_matches(sub {
			Class::Simple::Readonly::Cached->new(object => 'tulip', cache => {});
		}, qr/is a scalar/);

		my $object = new_ok('Class::Simple::Readonly::Cached' => [ cache => {} ]);

		does_carp_that_matches(sub {
			Class::Simple::Readonly::Cached->new(object => $object, cache => {});
		}, qr/is already cached/);

		done_testing();
	}
}
