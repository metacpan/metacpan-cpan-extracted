#!/usr/bin/env perl
# ex:ts=8 sw=4:
# Unit tests for the sans-IO Protocol::HAP::Server engine. The tests
# drive it over Protocol::HAP::Store::Memory with captured output;
# no socket exists anywhere in this file.

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use lib "$RealBin/../lib";

BEGIN {
	eval {
		require Math::BigInt;
		require Crypt::Ed25519;
		require Crypt::Curve25519;
		require Crypt::AuthEnc::ChaCha20Poly1305;
	};
	if ($@) {
		plan skip_all => 'Required modules not available';
	}
}

use_ok('Protocol::HAP::Server');
use_ok('Protocol::HAP::Store::Memory');
use_ok('Protocol::HAP::HTTP');
use_ok('Protocol::HAP::Pairing');

# Everything the engine writes, keyed by session id
my %OUT;

sub make_engine (%extra)
{
	return Protocol::HAP::Server->new(
		pin    => '123-45-678',
		name   => 'Test Bridge',
		store  => Protocol::HAP::Store::Memory->new,
		output => sub ( $session, $bytes ) {
			$OUT{ $session->id } .= $bytes;
		},
		%extra,
	);
}

# Test engine creation
{
	my $engine = make_engine();

	ok( defined $engine, 'engine created' );
	isa_ok( $engine, 'Protocol::HAP::Server' );
	ok( defined $engine->{store},   'store attached' );
	ok( defined $engine->{pairing}, 'pairing handler initialized' );
	ok( defined $engine->{bridge},  'bridge initialized' );
}

# The store and the output contract are required
{
	ok( !eval { Protocol::HAP::Server->new( pin => '123-45-678' ); 1 },
		'an engine without a store is a programming error' );
	ok( !eval {
			Protocol::HAP::Server->new(
				pin   => '123-45-678',
				store => Protocol::HAP::Store::Memory->new
			);
			1;
		},
		'an engine without an output contract is a programming error'
	);
}

# Test is_paired
{
	my $engine = make_engine();

	ok( !$engine->is_paired, 'not paired initially' );

	$engine->{store}->save_pairing( 'test-controller', 'X' x 32, 1 );
	ok( $engine->is_paired, 'paired after adding pairing' );
}

# Test get_device_id
{
	my $engine = make_engine();

	my $device_id = $engine->get_device_id;
	ok( defined $device_id, 'device ID generated' );
	like( $device_id, qr/^[0-9A-F]{2}(:[0-9A-F]{2}){5}$/,
		'device ID is MAC format' );
}

# Test event queue initialization ([HAP-HTTP §14] event notifications)
{
	my $engine = make_engine();

	ok( exists $engine->{event_queue}, '[HAP-HTTP §14] event queue exists' );
	ok( ref $engine->{event_queue} eq 'HASH', 'event queue is a hash' );
	ok( !defined $engine->{event_flush_timer},
		'no flush scheduled initially' );
}

# Test identity regeneration
{
	my $engine = make_engine();

	my $old_ltpk = $engine->{accessory_ltpk};
	ok( defined $old_ltpk, 'initial LTPK exists' );

	$engine->_regenerate_identity;

	my $new_ltpk = $engine->{accessory_ltpk};
	ok( defined $new_ltpk, 'new LTPK exists after regeneration' );
	isnt( $new_ltpk, $old_ltpk, 'LTPK changed after regeneration' );

	# Make sure the store has the new keys
	my ( undef, $stored_ltpk ) = $engine->{store}->load_accessory_keys;
	is( $stored_ltpk, $new_ltpk, 'new LTPK persisted to the store' );
}

# Test config number tracking ([HAP-mDNS §3.1] c# increments on change)
{
	my $store  = Protocol::HAP::Store::Memory->new;
	my $engine = make_engine( store => $store );

	is( $engine->update_config_number, 1,
		'[HAP-mDNS §3.1] first run keeps c# at 1' );
	is( $engine->update_config_number, 1,
		'unchanged database keeps c# stable' );

	# Rebuild over the same store: the c# does not change
	my $engine2 = make_engine( store => $store );
	is( $engine2->update_config_number, 1,
		'[HAP-mDNS §8] c# persisted across a rebuilt engine' );

	# Rebuild with an added accessory: the c# increments
	require App::OpenHAP::Tasmota::Heater;
	require App::OpenHAP::TestMock::MQTT;
	my $engine3 = make_engine( store => $store );
	$engine3->add_accessory(
		App::OpenHAP::Tasmota::Heater->new(
			aid         => 2,
			name        => 'New Heater',
			mqtt_topic  => 'heater',
			mqtt_client => App::OpenHAP::TestMock::MQTT->new,
		) );
	is( $engine3->update_config_number, 2,
		'[HAP-mDNS §3.1] c# increments when a device is added' );
	is( $engine3->mdns_txt_records->{'c#'}, 2, 'TXT c# reflects change' );
}

# on_pairing_changed fires when the paired state flips ([HAP-mDNS §8]).
# The host contract replaces the direct mDNS handle of the old server.
{
	my @flips;
	my $engine =
	    make_engine( on_pairing_changed => sub ($paired) {
			push @flips, $paired;
	    } );
	my $session = $engine->session_open;
	$session->set_verified('test-controller');

	# A request that does not change the pairing state calls nothing
	my $get = Protocol::HAP::HTTP::build_request(
		method => 'GET',
		path   => '/accessories',
	);
	$OUT{ $session->id } = '';
	$engine->receive( $session, $get );
	is( scalar @flips, 0, 'no callback without a state change' );

	# A pairing added through the store flips the state on the next
	# request
	$engine->{store}->save_pairing( 'controller', 'X' x 32, 1 );
	$engine->receive( $session, $get );
	is_deeply( \@flips, [1],
		'[HAP-mDNS §8] callback fires with paired=1' );

	$engine->{store}->remove_all_pairings;
	$engine->receive( $session, $get );
	is_deeply( \@flips, [ 1, 0 ], 'callback fires with paired=0' );
}

# The full pair-setup, pair-verify, and encrypted request flow, with
# no socket: the controller speaks to the engine through receive and
# the captured output.
subtest 'full pairing flow over the sans-IO engine' => sub {
	require Protocol::HAP::Controller;

	my $engine  = make_engine();
	my $session = $engine->session_open;

	my $transport = sub ($request_bytes) {
		$OUT{ $session->id } = '';
		$engine->receive( $session, $request_bytes ) or return;
		return delete $OUT{ $session->id };
	};

	my $controller = Protocol::HAP::Controller->new(
		pin           => '123-45-678',
		transport     => $transport,
		controller_id => 'openhap-test-ctrl',
	);

	ok( $controller->pair_setup,  'pair-setup completes' );
	ok( $controller->pair_verify, 'pair-verify completes' );
	ok( $session->is_encrypted,   'accessory session encrypted' );

	my $response = $controller->request( 'GET', '/accessories' );
	is( $response->{status}, 200, 'encrypted request round-trips' );
	like( $response->{body}, qr/"accessories"/,
		'accessory database returned over the encrypted session' );

	# A fatal condition: bytes that do not decrypt. receive
	# returns undef and the host closes the connection.
	ok( !defined $engine->receive( $session, 'garbage bytes' ),
		'undecryptable bytes are fatal for the connection' );

	# session_close releases what the session held
	$engine->session_close($session);
	ok( 1, 'session_close runs' );
};

# The JSON layer speaks octets, never wide-character strings. A
# non-ASCII value must reach the wire as UTF-8 bytes: the AEAD layer
# refuses wide characters, and Content-Length counts bytes. A codec
# without utf8 mode dies inside the encrypted session here.
subtest 'non-ASCII values survive the encrypted JSON path' => sub {
	require Protocol::HAP::Controller;

	my $engine  = make_engine( name => "Caf\x{e9} \x{65e5}\x{672c}" );
	my $session = $engine->session_open;

	my $transport = sub ($request_bytes) {
		$OUT{ $session->id } = '';
		$engine->receive( $session, $request_bytes ) or return;
		return delete $OUT{ $session->id };
	};

	my $controller = Protocol::HAP::Controller->new(
		pin           => '123-45-678',
		transport     => $transport,
		controller_id => 'openhap-test-ctrl',
	);

	ok( $controller->pair_setup,  'pair-setup completes' );
	ok( $controller->pair_verify, 'pair-verify completes' );

	my $response = $controller->request( 'GET', '/accessories' );
	ok( defined $response,
		'the encrypted response survives the non-ASCII name' );
	is( $response->{status}, 200, 'GET /accessories returns 200' );
	is( length( $response->{body} ),
		$response->{headers}{'content-length'},
		'Content-Length counts the UTF-8 bytes of the body' );

	# The name comes back as the same UTF-8 bytes it went in as
	my $expected = "Caf\x{e9} \x{65e5}\x{672c}";
	utf8::encode($expected);
	like( $response->{body}, qr/\Q$expected\E/,
		'the body carries the name as UTF-8 octets' );
};

done_testing();
