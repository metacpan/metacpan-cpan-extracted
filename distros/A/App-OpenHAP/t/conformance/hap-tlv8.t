#!/usr/bin/env perl
# ex:ts=8 sw=4:
# Conformance tests for spec/HAP-TLV8.md

use v5.36;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use lib "$RealBin/../lib";
use Fugu::TestLog;

use_ok('Protocol::HAP::TLV');
use_ok('Protocol::HAP::Pairing');

subtest '[HAP-TLV8 §1] basic record structure' => sub {
	my $encoded = Protocol::HAP::TLV::encode( 0x06, "\x01" );
	is( length($encoded), 3, 'record is type + length + value' );
	is( unpack( 'H*', $encoded ), '060101',
		'type, length and value bytes in order' );

	my $empty = Protocol::HAP::TLV::encode( 0x0A, '' );
	is( unpack( 'H*', $empty ), '0a00', 'zero-length value encodes' );
};

subtest '[HAP-TLV8 §2] fragmentation of long values' => sub {
	my $value   = 'X' x 500;
	my $encoded = Protocol::HAP::TLV::encode( 0x03, $value );

	# 500 bytes -> 255 + 245: 2 records with 2-byte headers each
	is( length($encoded), 500 + 4, 'two records for 500 bytes' );

	# The first fragment must be exactly 255 bytes
	my ( $t1, $l1 ) = unpack( 'CC', substr( $encoded, 0, 2 ) );
	is( $t1, 0x03, 'first fragment has value type' );
	is( $l1, 255,  'non-final fragment is exactly 255 bytes' );

	my ( $t2, $l2 ) = unpack( 'CC', substr( $encoded, 257, 2 ) );
	is( $t2, 0x03, 'second fragment has same type' );
	is( $l2, 245,  'final fragment carries the remainder' );

	# The decoder concatenates same-type records
	my %decoded = Protocol::HAP::TLV::decode($encoded);
	is( $decoded{0x03}, $value, 'fragments concatenated on decode' );
};

subtest '[HAP-TLV8 §8][HAP-TLV8 §8.2] 384-byte SRP key splits FF/81' =>
    sub {
	my $key     = 'K' x 384;
	my $encoded = Protocol::HAP::TLV::encode( 0x03, $key );

	is( length($encoded), 384 + 4, '384 bytes need two records' );
	is( unpack( 'C', substr( $encoded, 1, 1 ) ),
		0xFF, 'first fragment length byte is FF (255)' );
	is( unpack( 'C', substr( $encoded, 257 + 1, 1 ) ),
		0x81, 'second fragment length byte is 81 (129)' );

	my %decoded = Protocol::HAP::TLV::decode($encoded);
	is( length( $decoded{0x03} ), 384, 'round-trips to 384 bytes' );
};

subtest '[HAP-TLV8 §3] separators between list items' => sub {
	my $encoded = Protocol::HAP::TLV::encode(
		Protocol::HAP::Pairing::kTLVType_Separator(), '' );
	is( unpack( 'H*', $encoded ), 'ff00',
		'separator is type 0xFF with zero length' );
};

subtest '[HAP-TLV8 §4] value encodings' => sub {

	# [HAP-TLV8 §4.1] integers are little-endian and use the minimum
	# bytes
	is( unpack( 'H*', Protocol::HAP::TLV::encode( 0x0B, pack( 'C', 1 ) ) ),
		'0b0101', '[HAP-TLV8 §4.1] integer 1 encodes as 01' );
	is( unpack( 'H*', Protocol::HAP::TLV::encode( 0x0B, pack( 'v', 256 ) ) ),
		'0b020001',
		'[HAP-TLV8 §4.1] integer 256 encodes as 00 01 (LE)' );
	is( unpack( 'H*', Protocol::HAP::TLV::encode( 0x0B, pack( 'V', 65536 ) ) ),
		'0b0400000100',
		'[HAP-TLV8 §4.1] integer 65536 encodes as 00 00 01 00 (LE)' );

	# [HAP-TLV8 §4.2] strings without null terminator
	is( unpack( 'H*', Protocol::HAP::TLV::encode( 0x01, 'Hello' ) ),
		'010548656c6c6f',
		'[HAP-TLV8 §4.2] UTF-8 bytes, no null terminator' );

	# [HAP-TLV8 §4.3] binary data round-trips raw
	my $binary  = pack( 'H*', '00ff10deadbeef' );
	my %decoded =
	    Protocol::HAP::TLV::decode( Protocol::HAP::TLV::encode( 0x05, $binary ) );
	is( unpack( 'H*', $decoded{0x05} ),
		'00ff10deadbeef',
		'[HAP-TLV8 §4.3] raw bytes preserved' );

	# [HAP-TLV8 §4.4] a TLV value can be a nested TLV structure
	my $inner = Protocol::HAP::TLV::encode( 0x01, 'id', 0x0A, 'sig' );
	my %outer =
	    Protocol::HAP::TLV::decode( Protocol::HAP::TLV::encode( 0x05, $inner ) );
	my %nested = Protocol::HAP::TLV::decode( $outer{0x05} );
	is( $nested{0x01}, 'id',
		'[HAP-TLV8 §4.4] nested TLV decodes from sub-TLV value' );
	is( $nested{0x0A}, 'sig', '[HAP-TLV8 §4.4] all nested fields kept' );
};

subtest '[HAP-TLV8 §5] pairing TLV type codes' => sub {
	my %types = (
		Method        => 0x00,
		Identifier    => 0x01,
		Salt          => 0x02,
		PublicKey     => 0x03,
		Proof         => 0x04,
		EncryptedData => 0x05,
		State         => 0x06,
		Error         => 0x07,
		RetryDelay    => 0x08,
		Certificate   => 0x09,
		Signature     => 0x0A,
		Permissions   => 0x0B,
		FragmentData  => 0x0C,
		FragmentLast  => 0x0D,
		SessionID     => 0x0E,
		Flags         => 0x13,
		Separator     => 0xFF,
	);
	for my $name ( sort keys %types ) {
		my $constant = Protocol::HAP::Pairing->can("kTLVType_$name");
		ok( $constant, "kTLVType_$name defined" );
		is( $constant->(), $types{$name},
			sprintf( '[HAP-TLV8 §5/%s] kTLVType_%s is 0x%02X',
				$name, $name, $types{$name} ) );
	}
};

subtest '[HAP-TLV8 §7] pairing error codes' => sub {
	my %errors = (
		Unknown        => 0x01,
		Authentication => 0x02,
		Backoff        => 0x03,
		MaxPeers       => 0x04,
		MaxTries       => 0x05,
		Unavailable    => 0x06,
		Busy           => 0x07,
	);
	for my $name ( sort keys %errors ) {
		my $constant = Protocol::HAP::Pairing->can("kTLVError_$name");
		ok( $constant, "kTLVError_$name defined" );
		is( $constant->(), $errors{$name},
			sprintf( '[HAP-TLV8 §7/%s] kTLVError_%s is 0x%02X',
				$name, $name, $errors{$name} ) );
	}
};

subtest '[HAP-TLV8 §8.1] pair setup M1 wire bytes' => sub {
	my $m1 = Protocol::HAP::TLV::encode(
		Protocol::HAP::Pairing::kTLVType_State(),  pack( 'C', 1 ),
		Protocol::HAP::Pairing::kTLVType_Method(), pack( 'C', 0 ),
	);
	is( unpack( 'H*', $m1 ), '060101000100',
		'M1 request is 06 01 01 00 01 00' );

	my %decoded = Protocol::HAP::TLV::decode( pack( 'H*', '060101000100' ) );
	is( unpack( 'C', $decoded{0x06} ), 1, 'spec bytes decode State=M1' );
	is( unpack( 'C', $decoded{0x00} ), 0,
		'spec bytes decode Method=PairSetup' );
};

subtest '[HAP-TLV8 §8.3] error response wire bytes' => sub {
	my $error = Protocol::HAP::TLV::encode(
		Protocol::HAP::Pairing::kTLVType_State(), pack( 'C', 2 ),
		Protocol::HAP::Pairing::kTLVType_Error(),
		pack( 'C', Protocol::HAP::Pairing::kTLVError_Authentication() ),
	);
	is( unpack( 'H*', $error ), '060102070102',
		'M2 authentication error is 06 01 02 07 01 02' );
};

subtest '[HAP-TLV8 §9] base64 encoding in JSON' => sub {
	require MIME::Base64;

	# The spec example: "BgEBAAEA" decodes to the M1 request bytes
	my $decoded = MIME::Base64::decode_base64('BgEBAAEA');
	is( unpack( 'H*', $decoded ), '060101000100',
		'spec base64 example decodes to M1 bytes' );

	my %tlv = Protocol::HAP::TLV::decode($decoded);
	is( unpack( 'C', $tlv{0x06} ), 1, 'decoded TLV carries State=M1' );

	is( MIME::Base64::encode_base64( pack( 'H*', '060101000100' ), '' ),
		'BgEBAAEA', 'M1 bytes encode back to the spec base64' );
};

subtest '[HAP-TLV8 §10] parser rules with hostile buffers' => sub {

	# Rule 1: the parser keeps unknown types. They are not fatal.
	my %decoded =
	    Protocol::HAP::TLV::decode( pack( 'H*', '060101' . 'aa0142' ) );
	is( unpack( 'C', $decoded{0x06} ), 1, 'known type decoded' );
	is( $decoded{0xAA}, 'B', 'unknown type tolerated by parser' );

	# Rule 3: consecutive same types concatenate
	%decoded = Protocol::HAP::TLV::decode( pack( 'H*', '01024142' . '010243'
		    . '44' ) );
	is( $decoded{0x01}, 'ABCD', 'consecutive same types concatenate' );

	# Rule 4: zero-length values are valid
	%decoded = Protocol::HAP::TLV::decode( pack( 'H*', 'ff00' ) );
	ok( exists $decoded{0xFF}, 'zero-length value is valid' );
	is( $decoded{0xFF}, '', 'zero-length value is empty string' );

	# Malformed: length runs past end of buffer
	my @result = Protocol::HAP::TLV::decode( pack( 'H*', '06ff0102' ) );
	is( scalar @result, 0, 'length past end of buffer is rejected' );

	# Malformed: truncated record header (type without length)
	@result = Protocol::HAP::TLV::decode( pack( 'H*', '06010106' ) );
	is( scalar @result, 0, 'truncated record header is rejected' );

	# Malformed input to pair-setup returns an error TLV, not a crash
	require Protocol::HAP::Session;
	require Protocol::HAP::Store::File;
	require File::Temp;
	my $storage = Protocol::HAP::Store::File->new(
		path => File::Temp::tempdir( CLEANUP => 1 ) );
	my $pairing = Protocol::HAP::Pairing->new(
		pin            => '123-45-678',
		store        => $storage,
		accessory_ltsk => 'x' x 64,
		accessory_ltpk => 'y' x 32,
	);
	my $session  = Protocol::HAP::Session->new( id => 9001 );
	my $response =
	    $pairing->handle_pair_setup( pack( 'H*', '06ff0102' ), $session );
	my %resp = Protocol::HAP::TLV::decode($response);
	is( unpack( 'C', $resp{ Protocol::HAP::Pairing::kTLVType_Error() } ),
		Protocol::HAP::Pairing::kTLVError_Unknown(),
		'malformed pair-setup body answered with kTLVError_Unknown' );
};

done_testing();
