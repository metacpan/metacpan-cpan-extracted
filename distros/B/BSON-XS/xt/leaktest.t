use 5.008001;
use strict;
use warnings;
use Test::More 0.96;
binmode( Test::More->builder->$_, ":utf8" )
  for qw/output failure_output todo_output/;

BEGIN {
    plan skip_all => "Test::LeakTrace not installed"
      unless eval { require Test::LeakTrace; 1 };
    Test::LeakTrace->import(qw/no_leaks_ok/);
}

use BSON;
use BSON::Types ':all';
use Tie::IxHash;

#--------------------------------------------------------------------------#
# Fixtures
#--------------------------------------------------------------------------#

# output caching hashes
my %encoded;

my %data = (
    string  => "abc",
    integer => 42,
    float   => 3.14,
    regex   => qr/abc/ixm,
    hash    => { foo => "bar" },
    array   => [qw/one two three/],
);

$data{stringref} = \$data{string};

my %generators = (
    bson_bool      => sub { bson_bool(1) },
    bson_bytes     => sub { bson_bytes("abc") },
    bson_code      => sub { bson_code("abc") },
    bson_codescope => sub { bson_code( "abc", { x => 1 } ) },
    bson_dbref      => sub { bson_dbref( bson_oid(), "test" ) },
    bson_decimal128 => sub { bson_decimal128("123e1234") },
    bson_doc    => sub { bson_doc( x => 1 ) },
    bson_double => sub { bson_double(3.14) },
    bson_int32  => sub { bson_int32(42) },
    bson_int64  => sub { bson_int64(23) },
    bson_maxkey => sub { bson_maxkey() },
    bson_minkey => sub { bson_minkey() },
    bson_oid    => sub { bson_oid() },
    bson_raw    => sub { bson_raw("\x05\x00\x00\x00\x00") },
    bson_regex     => sub { bson_regex( "abc",         "ixmu" ) },
    bson_string    => sub { bson_string("abc") },
    bson_time      => sub { bson_time() },
    bson_timestamp => sub { bson_timestamp( 123456789, 42 ) },
);

my %encoders = (
    default => BSON->new(),
    numeric => BSON->new( prefer_numeric => 1 ),
    ordered => BSON->new( ordered => 1 ),
);

my %decoders = (
    default => BSON->new(),
    wrapper => BSON->new( wrap_numbers => 1, wrap_strings => 1 ),
);

# XXX conditionally add decoders based on availability of dt_type support

#--------------------------------------------------------------------------#
# warm up
#--------------------------------------------------------------------------#

# Warm up generators so that Moo constructs all necessary subs, since those
# closures often count as "leaks".

for my $key ( sort keys %generators ) {
    $generators{$key}->();
}

#--------------------------------------------------------------------------#
# tests
#--------------------------------------------------------------------------#

subtest "Check wrappers for leaks" => sub {
    # Test for leaks
    for my $key ( sort keys %generators ) {
        no_leaks_ok {
            $data{$key} = $generators{$key}->();
        }
        $key;
    }
};

for my $codec ( sort keys %encoders ) {
    subtest "Check '$codec' encoding for leaks" => sub {
        # Test for leaks
        for my $key ( sort keys %data ) {
            my $case = "$key|$codec";
            # Cache encoded BSON doc from plain hashref case only
            no_leaks_ok {
                $encoded{$case} = $encoders{$codec}->encode_one( { a => $data{$key} } );
            }
            "$case (hashref)";
            no_leaks_ok {
                $encoded{$case} =
                  $encoders{$codec}->encode_one( Tie::IxHash->new( a => $data{$key} ) );
            }
            "$case (ixhash)";
            no_leaks_ok {
                $encoded{$case} =
                  $encoders{$codec}->encode_one( bson_doc( a => $data{$key} ) );
            }
            "$case (bsondoc)";
        }
    };
}

for my $codec ( sort keys %decoders ) {
    subtest "Check '$codec' decoding for leaks" => sub {
        # Test for leaks
        for my $key ( sort keys %encoded ) {
            my $case = "$key|$codec";
            no_leaks_ok {
                $decoders{$codec}->decode_one( $encoded{$key} );
            }
            $case;
        }
    };
}

done_testing;
#
# This file is part of BSON-XS
#
# This software is Copyright (c) 2019 by MongoDB, Inc.
#
# This is free software, licensed under:
#
#   The Apache License, Version 2.0, January 2004
#

# vim: set ts=4 sts=4 sw=4 et tw=75:
