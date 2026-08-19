#!/usr/bin/env perl
# ex:ts=8 sw=4:
# Protocol::HAP::Store::File - what the durable store keeps on disk.
#
# The contract itself is proven over both implementations in
# t/protocol/store.t. This file proves what is specific to files: the
# layout on disk, the mode of every file the store creates, and the
# counters that survive a restart.

use v5.36;
use Test::More;
use File::Temp qw(tempdir);

use_ok('Protocol::HAP::Store::File');

# mode_of($path):
#	The permission bits of a file, or undef when it is absent.
sub mode_of ($path)
{
	return unless -e $path;
	return ( stat $path )[2] & 07777;
}

subtest 'the constructor' => sub {
	my $dir   = tempdir( CLEANUP => 1 );
	my $store = Protocol::HAP::Store::File->new( path => "$dir/state" );

	isa_ok( $store, 'Protocol::HAP::Store::File' );
	ok( -d "$dir/state", 'the constructor created the directory' );
	is( mode_of("$dir/state"), 0700, 'and which no other user can read' );

	# The path is host policy. This module carries no default.
	my $ok = eval { Protocol::HAP::Store::File->new; 1 };
	ok( !$ok, 'new without a path dies' );
	like( $@, qr/path parameter required/, 'and says why' );
};

subtest 'the accessory identity' => sub {
	my $dir   = tempdir( CLEANUP => 1 );
	my $store = Protocol::HAP::Store::File->new( path => $dir );

	is_deeply( [ $store->load_accessory_keys ],
		[], 'a fresh store holds no identity' );

	my $ltsk = pack 'H*', '11' x 64;
	my $ltpk = pack 'H*', '22' x 32;
	$store->save_accessory_keys( $ltsk, $ltpk );

	my ( $loaded_ltsk, $loaded_ltpk ) = $store->load_accessory_keys;
	is( $loaded_ltsk, $ltsk, 'the secret key round-trips as bytes' );
	is( $loaded_ltpk, $ltpk, 'and so does the public key' );
};

subtest 'the pairings' => sub {
	my $dir   = tempdir( CLEANUP => 1 );
	my $store = Protocol::HAP::Store::File->new( path => $dir );

	is_deeply( $store->load_pairings, {}, 'a fresh store holds no pairing' );

	$store->save_pairing( 'controller-1', 'ltpk1', 1 );
	$store->save_pairing( 'controller-2', 'ltpk2', 0 );

	my $pairings = $store->load_pairings;
	is( scalar keys %$pairings, 2, 'both pairings load' );
	is( $pairings->{'controller-1'}{ltpk}, 'ltpk1', 'the first key' );
	is( $pairings->{'controller-1'}{permissions}, 1, 'the admin is admin' );
	is( $pairings->{'controller-2'}{permissions}, 0, 'the user is not' );

	$store->remove_pairing('controller-1');
	$pairings = $store->load_pairings;
	ok( !exists $pairings->{'controller-1'}, 'a removal removes' );
	ok( exists $pairings->{'controller-2'},  'and only the named one' );

	# The file holds the key as hex, so an arbitrary byte survives.
	my $binary = pack 'H*', 'deadbeef' . ( 'aa' x 12 );
	$store->save_pairing( 'binary-controller', $binary, 1 );
	is( $store->load_pairings->{'binary-controller'}{ltpk},
		$binary, 'a binary key round-trips through the hex format' );
};

# The mode protects the identity of the accessory. The store applies it
# at the open, before the first byte: a chmod after the write leaves a
# window in which a secret is world-readable. Nothing asserted the mode
# of accessory_ltsk or pairings.db before this file.
subtest 'the mode of every file the store creates' => sub {
	my $dir   = tempdir( CLEANUP => 1 );
	my $store = Protocol::HAP::Store::File->new( path => $dir );

	$store->save_accessory_keys( 'ltsk', 'ltpk' );
	$store->save_pairing( 'controller-1', 'ltpk1', 1 );
	$store->set_auth_attempts(2);

	is( mode_of("$dir/accessory_ltsk"), 0600, 'the secret key is 0600' );
	is( mode_of("$dir/accessory_ltpk"), 0644, 'the public key is 0644' );
	is( mode_of("$dir/pairings.db"), 0600,
		'the pairing records are 0600' );
	is( mode_of("$dir/state.json"), 0600, 'the counters are 0600' );

	# An existing file keeps its own mode through an open. A rewrite
	# must narrow it anyway, or a file that was once wide stays wide.
	chmod 0666, "$dir/accessory_ltsk", "$dir/pairings.db"
	    or die "chmod: $!";
	$store->save_accessory_keys( 'ltsk2', 'ltpk2' );
	$store->save_pairing( 'controller-2', 'ltpk2', 0 );

	is( mode_of("$dir/accessory_ltsk"), 0600,
		'a rewrite narrows a widened secret key' );
	is( mode_of("$dir/pairings.db"), 0600,
		'and a widened pairings file' );
};

# The counters live in one state file, at mode 0600. A restart must
# find them where it left them: a controller that sees c# go backwards
# drops the accessory and the owner has to pair again.
subtest 'the counters survive a restart' => sub {
	my $dir   = tempdir( CLEANUP => 1 );
	my $store = Protocol::HAP::Store::File->new( path => $dir );

	is( $store->get_config_number, 1,     'the number starts at 1' );
	is( $store->get_auth_attempts, 0,     'and the attempts at 0' );
	is( $store->get_config_digest, undef, 'with no digest yet' );

	$store->save_config_digest('b1946ac92492d2347c6235b4d2611184');
	$store->set_auth_attempts(3);
	is( $store->increment_config_number, 2, 'c# starts at 1 and goes up' );

	ok( -f "$dir/state.json", 'the counters are in a state file' );
	is( mode_of("$dir/state.json"), 0600,
		'which no other user can read' );

	my $again = Protocol::HAP::Store::File->new( path => $dir );
	is( $again->get_config_number, 2,
		'[HAP-Pairing §7.2] the configuration number survives' );
	is( $again->get_config_digest,
		'b1946ac92492d2347c6235b4d2611184',
		'the configuration digest survives' );
	is( $again->get_auth_attempts, 3,
		'[HAP-Pairing §8] the failed-attempt counter survives' );
};

subtest 'a corrupt state file does not stop the store' => sub {
	my $dir = tempdir( CLEANUP => 1 );
	Protocol::HAP::Store::File->new( path => $dir )->set_auth_attempts(9);

	open my $fh, '>', "$dir/state.json" or die "open: $!";
	print {$fh} '{ this is not json' or die "print: $!";
	close $fh;

	my $store = Protocol::HAP::Store::File->new( path => $dir );
	is( $store->get_auth_attempts, 0, 'the state reads as empty' );
	is( $store->get_config_number, 1, 'and the number falls back to 1' );

	# The store must be able to write over the corrupt file.
	$store->set_auth_attempts(1);
	is( Protocol::HAP::Store::File->new( path => $dir )->get_auth_attempts,
		1, 'and the next write repairs it' );
};

# The store belongs to the protocol tier now, so it must reach no host
# module. t/protocol/boundary.t proves this over the source. This
# subtest proves it over the loaded program, where an import that
# arrived through another module would also show.
subtest 'the store loads no host module' => sub {
	my @host = grep { /^(?:Fugu|App)\b/ }
	    map { s{/}{::}gr =~ s{\.pm$}{}r } sort keys %INC;

	is_deeply( \@host, [], 'no Fugu or App module is loaded' )
	    or diag( join ' ', @host );
};

done_testing();
