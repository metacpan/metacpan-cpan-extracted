#!perl -w

use strict;
use warnings;
use autodie qw(:all);

use Class::Simple;
use Class::Simple::Readonly::Cached;
use CHI;
use Test::Most;
use Test::Needs 'Test::Carp';

CARP: {
	Test::Carp->import();

	# Calling new() with no args causes Params::Get to Carp::confess (not croak),
	# so we use throws_ok from Test::Exception (bundled in Test::Most) which
	# catches any die/croak/confess.
	throws_ok { Class::Simple::Readonly::Cached->new() } qr/Usage:/,
		'new() without args dies with usage message';

	does_croak_that_matches(sub {
		Class::Simple::Readonly::Cached->new({ foo => 'bar' })
	}, qr/Cache must be ref to HASH or object\z/);

	does_croak_that_matches(sub {
		Class::Simple::Readonly::Cached->new(\'foo');
	}, qr/Cache must be ref to HASH or object\z/);

	# Partition: non-HASH unblessed ref (ARRAY ref) as cache.
	# Premise:   ref([]) = 'ARRAY', blessed([]) = undef.
	# Conclusion: the cache-validation guard croaks at the same boundary
	#             as the scalar-ref test above, but proves the ref-type
	#             check covers all non-HASH refs, not just SCALAR.
	does_croak_that_matches(sub {
		Class::Simple::Readonly::Cached->new(cache => [], object => Class::Simple->new());
	}, qr/Cache must be ref to HASH or object\z/);

	does_carp_that_matches(sub {
		Class::Simple::Readonly::Cached->new(object => 'tulip', cache => {});
	}, qr/must be a reference, not a scalar/);

	my $object = new_ok('Class::Simple::Readonly::Cached' => [ cache => {} ]);

	does_carp_that_matches(sub {
		Class::Simple::Readonly::Cached->new({ object => $object, cache => {} });
	}, qr/is already a cached object/);

	my $l = new_ok('Class::Simple' => [ cache => {} ]);
	$object = new_ok('Class::Simple::Readonly::Cached' => [ cache => {}, object => $l ]);
	my $object2;
	does_carp_that_matches(sub {
		$object2 = new_ok('Class::Simple::Readonly::Cached' => [ cache => {}, object => $l ]);
	}, qr/is already cached at /);

	cmp_ok($object, 'eq', $object2,
		'attempting to cache an already-cached object returns the existing wrapper');

	# TODO: add does_not_carp once Test::Carp supports it
	$object2 = new_ok('Class::Simple::Readonly::Cached' =>
		[ cache => {}, object => $l, quiet => 1 ]);

	cmp_ok($object, 'eq', $object2,
		'quiet => 1 suppresses the warning and still returns the existing wrapper');

	done_testing();
}
