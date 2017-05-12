use strict;
use Test::More;

BEGIN { require 't/base.include' }

SKIP: {
    eval {
        require JSON::PP;
        JSON::PP->import;
    };
    skip 'Needs JSON::PP', 1 if $@;

    my $dump = p( JSON::PP->new->decode(input) );
    is( $dump, expected, "JSON::PP, live" );
}

my $emulated = {
    alpha => bless( \do { my $v = 1 }, 'JSON::PP::Boolean' ),
    beta  => bless( \do { my $v = 0 }, 'JSON::PP::Boolean' ),
};
$emulated->{gamma} = $emulated->{alpha};
$emulated->{zeta}  = $emulated->{beta};

is( p($emulated), expected, "JSON::PP, emulated" );

done_testing;
