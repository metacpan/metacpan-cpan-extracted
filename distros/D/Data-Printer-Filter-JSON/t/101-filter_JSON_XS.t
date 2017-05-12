use strict;
use Test::More;

BEGIN { require 't/base.include' }

SKIP: {
    eval {
        require JSON::XS;
        JSON::XS->import(qw/decode_json/);
    };
    skip "JSON::XS not installed", 1 if $@;
    my $dump = p( decode_json(input) );
    is( $dump, expected, "JSON:XS, live" );
}

my $emulated = {
    alpha => bless( \do { my $v = 1 }, 'JSON::XS::Boolean' ),
    beta  => bless( \do { my $v = 0 }, 'JSON::XS::Boolean' ),
};
$emulated->{gamma} = $emulated->{alpha};
$emulated->{zeta}  = $emulated->{beta};

is( p($emulated), expected, "JSON::XS, emulated" );

done_testing;
