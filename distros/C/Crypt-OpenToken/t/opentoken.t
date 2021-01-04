#!/usr/bin/perl

use strict;
use warnings;
use if $ENV{AUTOMATED_TESTING}, 'Test::DiagINC'; use Test::More tests => 3;
use Test::Exception;
use Crypt::OpenToken;

###############################################################################
# TEST: instantiation without password; fails
instantiation_no_key: {
    throws_ok { Crypt::OpenToken->new() } qr/password.*required/,
        '"password" is a required parameter';
}

###############################################################################
# TEST: instantiation
instantiation: {
    my $factory = Crypt::OpenToken->new(password => 'abc123');
    isa_ok $factory, 'Crypt::OpenToken', 'instantiated token factory';
}

###############################################################################
# TEST: base64 en/decoding
base64_encoding: {
    # encoded test data taken from OTK IETF Draft
    my $encoded = "UFRLAQK9THj0okLTUB663QrJFg5qA58IDhAb93ondvcx7sY6s44eszNqAAAga5W8Dc4XZwtsZ4qV3_lDI-Zn2_yadHHIhkGqNV5J9kw*";

    my $factory   = Crypt::OpenToken->new(password => 'dummy password');
    my $decoded   = $factory->_base64_decode($encoded);
    my $roundtrip = $factory->_base64_encode($decoded);
    is $roundtrip, $encoded, 'Base64 decode/encode round-trip';
}
