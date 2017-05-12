#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use ok 'Crypt::Util' => (
	qw/:crypt default_key exported_instance encode_string/,
	defaults => {
		key    => "moose",
		encode => 1,
	},
);

is( default_key, "moose", "default key set through defaults" );

default_key("bar");

is( default_key, "bar", "can be used as a setter, too" );

isa_ok( exported_instance, "Crypt::Util" );

like(
	encode_string("eagles may soar, but cows don't get sucked into jet engines"),
	qr/^[a-f0-9]+$/,
	"encode",
);

