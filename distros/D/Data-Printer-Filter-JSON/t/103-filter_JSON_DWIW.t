use strict;
use Test::More;

BEGIN { require 't/base.include' }

SKIP: {
    eval { 
        require JSON::DWIW;
        JSON::DWIW->import(qw/from_json deserialize_json/);
    };
    skip 'Needs JSON::DWIW', 1 if $@;

    is( p( from_json( input, { convert_bool => 1 } ) ),
        expected, "JSON:DWIW, from_json, live" );
}

my $emulated = {
    alpha => bless( do { \( my $v = 1 ) }, 'JSON::DWIW::Boolean' ),
    beta  => bless( do { \( my $v = 0 ) }, 'JSON::DWIW::Boolean' ),
    gamma => bless( do { \( my $v = 1 ) }, 'JSON::DWIW::Boolean' ),
    zeta  => bless( do { \( my $v = 0 ) }, 'JSON::DWIW::Boolean' ),
};

is( p($emulated), expected, "JSON::DWIW, emulated" );

done_testing;
