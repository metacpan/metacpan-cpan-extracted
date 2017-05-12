use strict;
use Test::More;

BEGIN { require 't/base.include' }

SKIP: {
    eval {
        require Pegex::JSON;
        Pegex::JSON->import;
    };
    skip 'Needs Pegex::JSON', 1 if $@;

    my $dump = p( Pegex::JSON->parse(input) );
    is( $dump, expected, "Pegex::JSON (boolean), live" );
}

my $emulated = {
    alpha => bless( do { \( my $o = 1 ) }, 'boolean' ),
    beta  => bless( do { \( my $o = 0 ) }, 'boolean' ),
};
$emulated->{gamma} = $emulated->{alpha};
$emulated->{zeta}  = $emulated->{beta};

is( p($emulated), expected, "Pegex::JSON (boolean), emulated" );

done_testing;
