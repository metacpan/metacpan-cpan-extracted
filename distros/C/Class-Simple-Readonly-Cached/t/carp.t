#!perl -wT

use strict;
use warnings;
use Class::Simple;
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
			Class::Simple::Readonly::Cached->new({ object => $object, cache => {} });
		}, qr/is a cached object/);


		my $l = new_ok('Class::Simple' => [ cache => {} ]);
		$object = new_ok('Class::Simple::Readonly::Cached' => [ cache => {}, object => $l ]);
		my $object2;
		does_carp_that_matches(sub {
			$object2 = new_ok('Class::Simple::Readonly::Cached' => [ cache => {}, object => $l ]);
		}, qr/is already cached at /);

		cmp_ok($object, 'eq', $object2, 'attempt to cache a previously cached object returns the same cache');

		# TODO "does_not_carp" when that is added to Test::Carp
		$object2 = new_ok('Class::Simple::Readonly::Cached' => [ cache => {}, object => $l, quiet => 1 ]);

		cmp_ok($object, 'eq', $object2, 'attempt to cache a previously cached object returns the same cache');

		done_testing();
	}
}
