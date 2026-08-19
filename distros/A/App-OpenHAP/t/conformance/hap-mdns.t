#!/usr/bin/env perl
# ex:ts=8 sw=4:
# Conformance tests for spec/HAP-mDNS.md

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use lib "$RealBin/../lib";
use Fugu::TestLog;
use File::Temp qw(tempdir);
use Digest::SHA qw(sha512);
use MIME::Base64 qw(encode_base64);

BEGIN {
	eval { require Crypt::Ed25519; require JSON::XS; };
	if ($@) {
		plan skip_all => 'Required modules not available';
	}
}

use_ok('Protocol::HAP::Server');
use_ok('Protocol::HAP::Store::Memory');
use_ok('Fugu::Mdnsd');

sub make_hap (%extra)
{
	return Protocol::HAP::Server->new(
		pin    => '123-45-678',
		name   => 'mDNS Bridge',
		store  => Protocol::HAP::Store::Memory->new,
		output => sub ( $, $ ) { },
		%extra,
	);
}

subtest '[HAP-mDNS §1] service type is hap over tcp' => sub {

	# openhapd publishes app 'hap' over proto 'tcp'. mdnsd itself
	# prepends the underscores to form _hap._tcp.local. The mdns
	# integration test asserts the browse of _hap._tcp.
	my $mdns = Fugu::Mdnsd->new;
	ok( !defined $mdns->publish_service(
			name  => 'mDNS Bridge',
			app   => 'hap',
			proto => 'not-ip',
			port  => 51827,
			txt   => '',
		),
		'a protocol other than tcp/udp cannot be advertised'
	);
	like( $mdns->error, qr/tcp or udp/, 'rejected at validation' );

	ok( !defined $mdns->publish_service(
			name  => 'mDNS Bridge',
			app   => 'hap',
			proto => 'tcp',
			port  => 51827,
			txt   => '',
		),
		'hap/tcp fails only for the missing connection'
	);
	is( $mdns->error, 'not connected',
		'the hap/tcp service type passes validation' );
};

subtest '[HAP-mDNS §2] required TXT record fields' => sub {
	my $hap = make_hap();
	my $txt = $hap->mdns_txt_records;

	for my $key (qw(c# ff id md pv s# sf ci)) {
		ok( exists $txt->{$key},
			"[HAP-mDNS §2/$key] required field $key present" );
	}
	ok( !exists $txt->{sh},
		'[HAP-mDNS §2/sh] optional sh absent without setup_id' );
};

subtest '[HAP-mDNS §3] field values' => sub {
	my $hap = make_hap();
	my $txt = $hap->mdns_txt_records;

	is( $txt->{ff}, 0, '[HAP-mDNS §3.2] feature flags are 0' );
	is( $txt->{md}, 'mDNS Bridge',
		'[HAP-mDNS §3.4] model name matches display name' );
	like( $txt->{'s#'}, qr/^\d+$/, '[HAP-mDNS §3.6] s# is numeric' );
	cmp_ok( $txt->{'s#'}, '>=', 1,
		'[HAP-mDNS §3.6] state number starts at 1' );
};

subtest '[HAP-mDNS §9] complete TXT record' => sub {
	my $hap = make_hap( setup_id => 'XYZQ' );
	my $txt = $hap->mdns_txt_records;

	# All fields of the complete example are present with sane values
	like( $txt->{'c#'}, qr/^\d+$/,   'c# numeric' );
	is( $txt->{ff}, 0, 'ff zero' );
	like( $txt->{id}, qr/^[0-9A-F:]+$/, 'id MAC-like' );
	ok( length( $txt->{md} ),  'md present' );
	ok( length( $txt->{pv} ),  'pv present' );
	like( $txt->{'s#'}, qr/^\d+$/, 's# numeric' );
	like( $txt->{sf}, qr/^[01]$/, 'sf is 0 or 1' );
	like( $txt->{ci}, qr/^\d+$/,  'ci numeric' );
	ok( length( $txt->{sh} ), 'sh present with setup_id' );
};

subtest '[HAP-mDNS §10] bridge advertises a single service' => sub {

	# One mDNS service covers the bridge and all bridged accessories.
	# openhapd does not advertise individual bridged accessories
	# separately. openhapd formats exactly one TXT string for that
	# one service.
	my $hap = make_hap();
	my $txt = Fugu::Mdnsd::format_txt( %{ $hap->mdns_txt_records } );
	ok( length($txt), 'single TXT string for the bridge' );
	like( $txt, qr/(?:^|\.)ci=2(?:\.|$)/,
		'advertised category is Bridge for all bridged accessories'
	);
};

subtest '[HAP-mDNS §3.1] configuration number' => sub {
	my $hap = make_hap();
	my $txt = $hap->mdns_txt_records;

	like( $txt->{'c#'}, qr/^\d+$/, 'c# is numeric' );
	cmp_ok( $txt->{'c#'}, '>=', 1, 'c# starts at 1' );

	# c# increments when the accessory database changes
	$hap->{store}->increment_config_number;
	my $txt2 = $hap->mdns_txt_records;
	is( $txt2->{'c#'}, $txt->{'c#'} + 1,
		'c# increments on configuration change ([HAP-mDNS §8])' );
};

subtest '[HAP-mDNS §3.3] device ID format' => sub {
	my $hap = make_hap();
	my $id  = $hap->get_device_id;

	like( $id, qr/^[0-9A-F]{2}(:[0-9A-F]{2}){5}$/,
		'device ID is uppercase MAC-like format' );
	is( $hap->mdns_txt_records->{id},
		$id, 'TXT id field carries the device ID' );
};

subtest '[HAP-mDNS §3.5] protocol version' => sub {
	my $hap = make_hap();

	# pv=1 rather than 1.1: mdnsd uses '.' as the TXT record
	# delimiter and cannot escape it. HomeKit accepts pv=1.
	is( $hap->mdns_txt_records->{pv},
		'1', 'pv advertised (1, see mdnsd delimiter note)' );
};

subtest '[HAP-mDNS §3.7] status flags follow pairing state' => sub {
	my $hap = make_hap();

	is( $hap->mdns_txt_records->{sf},
		1, 'sf=1 (bit 0 set) when not paired' );

	$hap->{store}->save_pairing( 'controller', 'X' x 32, 1 );
	is( $hap->mdns_txt_records->{sf},
		0, 'sf=0 once paired ([HAP-mDNS §8] pairing added)' );

	$hap->{store}->remove_all_pairings;
	is( $hap->mdns_txt_records->{sf},
		1, 'sf returns to 1 when pairing removed' );
};

subtest '[HAP-mDNS §3.8] category identifier' => sub {
	my $hap = make_hap();
	is( $hap->mdns_txt_records->{ci}, 2, 'ci=2 for a bridge' );
};

subtest '[HAP-mDNS §3.9] setup hash with fixed vector' => sub {
	my $hap = make_hap( setup_id => 'XYZQ' );

	# Pin the device ID by fixing the LTPK-derived identity
	$hap->{accessory_ltpk} = pack( 'H*', '00ffaabbccdd' . 'ee' x 26 );
	is( $hap->get_device_id, '00:FF:AA:BB:CC:DD',
		'fixed LTPK yields fixed device ID' );

	# setupHash = Base64(SHA512(SetupID + DeviceID.uppercase())[0:4])
	my $expected = encode_base64(
		substr( sha512( 'XYZQ' . '00:FF:AA:BB:CC:DD' ), 0, 4 ), '' );
	my $txt = $hap->mdns_txt_records;
	is( $txt->{sh}, $expected,
		'sh is Base64 of first 4 SHA-512 bytes over '
		    . 'SetupID + DeviceID' );
	is( length($txt->{sh}), 8, '4 hash bytes encode to 8 base64 chars' );
};

subtest '[HAP-mDNS §4] service instance name' => sub {
	my $hap = make_hap();
	is( $hap->mdns_txt_records->{md},
		'mDNS Bridge', 'model name matches the display name' );

	# The display name is the instance name that openhapd publishes.
	# It goes into the name field of the advertised service.
	my $mdns = Fugu::Mdnsd->new;
	$mdns->{service} = {
		name  => $hap->{name},
		app   => 'hap',
		proto => 'tcp',
		port  => 51827,
		txt   => '',
	};
	is( unpack( 'Z*', substr( $mdns->_encode_service, 84, 256 ) ),
		'mDNS Bridge', 'service advertised under the display name' );
};

subtest '[HAP-mDNS §6] port' => sub {

	# The advertised port is the port that openhapd listens on. It
	# goes into the port field of the service structure.
	my $mdns = Fugu::Mdnsd->new;
	$mdns->{service} = {
		name  => 'x',
		app   => 'hap',
		proto => 'tcp',
		port  => 51827,
		txt   => '',
	};
	is( unpack( 'S', substr( $mdns->_encode_service, 600, 2 ) ),
		51827, 'default HAP port 51827 advertised' );

	$mdns->{service}{port} = 8080;
	is( unpack( 'S', substr( $mdns->_encode_service, 600, 2 ) ),
		8080, 'any available port can be advertised' );
};

done_testing();
