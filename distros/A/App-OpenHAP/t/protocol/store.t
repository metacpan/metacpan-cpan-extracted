#!/usr/bin/env perl
# ex:ts=8 sw=4:
# The store contract of Protocol::HAP, over every implementation.
#
# Protocol/HAP/Store.pod defines twelve methods. The engine calls
# those and no others, so a store that answers them differently
# breaks a paired home and nothing else notices. This file drives both
# implementations through one loop, so the two can never drift.
#
# Above all it proves the increment rule, which the contract calls a
# rule with no slack: save_pairing, remove_pairing, and
# remove_all_pairings each move c# by exactly one. A store that skips
# the increment hides pairing changes from controllers; an engine that
# adds one on top counts every change twice.

use v5.36;
use Test::More;
use File::Temp qw(tempdir);

use Protocol::HAP::Store::File;
use Protocol::HAP::Store::Memory;

# The twelve methods, in the order that Store.pod documents them.
my @CONTRACT = qw(
    load_accessory_keys save_accessory_keys
    load_pairings save_pairing remove_pairing remove_all_pairings
    get_config_number increment_config_number
    get_config_digest save_config_digest
    get_auth_attempts set_auth_attempts
);

# Each entry builds a fresh store. A file store needs a directory of
# its own for every call, so the builder makes one.
my @IMPLEMENTATIONS = (
	{
		name  => 'Protocol::HAP::Store::Memory',
		build => sub { return Protocol::HAP::Store::Memory->new },
	},
	{
		name  => 'Protocol::HAP::Store::File',
		build => sub {
			return Protocol::HAP::Store::File->new(
				path => tempdir( CLEANUP => 1 ) );
		},
	},
);

for my $implementation (@IMPLEMENTATIONS) {
	my $name  = $implementation->{name};
	my $build = $implementation->{build};

	subtest "$name answers the twelve methods" => sub {
		my $store = $build->();
		ok( $store->can($_), "it provides $_" ) for @CONTRACT;
	};

	subtest "$name holds the accessory identity" => sub {
		my $store = $build->();

		is_deeply( [ $store->load_accessory_keys ],
			[], 'a fresh store returns the empty list' );

		my $ltsk = pack 'H*', '11' x 64;
		my $ltpk = pack 'H*', '22' x 32;
		$store->save_accessory_keys( $ltsk, $ltpk );

		is_deeply( [ $store->load_accessory_keys ],
			[ $ltsk, $ltpk ], 'and the pair after a save' );
	};

	subtest "$name holds the pairings" => sub {
		my $store = $build->();

		is_deeply( $store->load_pairings, {},
			'a fresh store holds no pairing' );

		$store->save_pairing( 'admin-ctrl', 'ltpk-a', 1 );
		$store->save_pairing( 'user-ctrl',  'ltpk-u', 0 );

		my $pairings = $store->load_pairings;
		is( scalar keys %$pairings, 2, 'both pairings load' );
		is( $pairings->{'admin-ctrl'}{ltpk}, 'ltpk-a',
			'the key comes back as it went in' );
		is( $pairings->{'admin-ctrl'}{permissions},
			1, 'an admin is an admin' );
		is( $pairings->{'user-ctrl'}{permissions},
			0, 'and a regular controller is not' );

		# permissions defaults to 1
		$store->save_pairing( 'default-ctrl', 'ltpk-d' );
		is( $store->load_pairings->{'default-ctrl'}{permissions},
			1, 'permissions defaults to admin' );

		# A replacement is not a second record
		$store->save_pairing( 'admin-ctrl', 'ltpk-new', 0 );
		$pairings = $store->load_pairings;
		is( scalar keys %$pairings, 3, 'a replacement adds no record' );
		is( $pairings->{'admin-ctrl'}{ltpk},
			'ltpk-new', 'and it replaces the key' );
		is( $pairings->{'admin-ctrl'}{permissions},
			0, 'and the permissions' );

		$store->remove_pairing('user-ctrl');
		ok( !exists $store->load_pairings->{'user-ctrl'},
			'a removal removes the named pairing' );

		# Removing an unknown id is not an error
		my $ok = eval { $store->remove_pairing('no-such-ctrl'); 1 };
		ok( $ok, 'removing an unknown id is not an error' );

		$store->remove_all_pairings;
		is_deeply( $store->load_pairings, {},
			'remove_all_pairings clears every record' );
	};

	subtest "$name holds the counters" => sub {
		my $store = $build->();

		is( $store->get_config_number, 1, 'c# starts at 1' );
		is( $store->increment_config_number, 2,
			'an increment returns the new value' );
		is( $store->get_config_number, 2, 'and the store keeps it' );

		is( $store->get_config_digest, undef, 'no digest at first' );
		$store->save_config_digest('a-digest');
		is( $store->get_config_digest, 'a-digest',
			'and the stored one afterwards' );

		is( $store->get_auth_attempts, 0, 'no failed attempt yet' );
		$store->set_auth_attempts(5);
		is( $store->get_auth_attempts, 5, 'and the count afterwards' );
		$store->set_auth_attempts(0);
		is( $store->get_auth_attempts, 0, 'a reset resets' );
	};

	# The increment rule. Each mutating pairing method moves c# by
	# exactly one: no store may skip it, and none may double it.
	subtest "$name moves c# on every pairing change" => sub {
		my $store = $build->();

		for my $change (
			[ 'save_pairing', sub { $_[0]->save_pairing( 'c1', 'k1', 1 ) } ],
			[ 'save_pairing over an existing record',
				sub { $_[0]->save_pairing( 'c1', 'k2', 0 ) } ],
			[ 'remove_pairing', sub { $_[0]->remove_pairing('c1') } ],
			[ 'remove_pairing of an unknown id',
				sub { $_[0]->remove_pairing('c9') } ],
			[ 'remove_all_pairings',
				sub { $_[0]->remove_all_pairings } ],
		    )
		{
			my ( $what, $code ) = @$change;
			my $before = $store->get_config_number;
			$code->($store);
			is( $store->get_config_number, $before + 1,
				"$what moves c# by one" );
		}
	};
}

done_testing();
