use strict;
use Test::More;

BEGIN { require 't/base.include' }

SKIP: {
    eval {
        require Mojo::JSON;
        Mojo::JSON->import;
    };
    skip 'Needs Mojo::JSON', 1 if $@;

    my $dump = p( Mojo::JSON->new->decode(input) );
    is( $dump, expected, "JSON:SL, live" );
}

my $emulated = {
    'alpha' => bless( do { \( my $o = 1 ) }, 'Mojo::JSON::_Bool' ),
    'beta'  => bless( do { \( my $o = 0 ) }, 'Mojo::JSON::_Bool' ),
};
$emulated->{gamma} = $emulated->{alpha};
$emulated->{zeta}  = $emulated->{beta};

is( p($emulated), expected, "Mojo::JSON, emulated" );

done_testing;
