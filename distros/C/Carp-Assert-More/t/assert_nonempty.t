#!perl -Tw

use warnings;
use strict;

use Test::More tests => 12;
use Test::Exception;

use Carp::Assert::More;

use constant PASS => 1;
use constant FAIL => 0;

my @cases = (
    [ 0         => FAIL ],
    [ 'foo'     => FAIL ],
    [ undef     => FAIL ],
    [ {}        => FAIL ],
    [ []        => FAIL ],
    [ {foo=>1}  => PASS ],
    [ [1,2,3]   => PASS ],
);

for my $case ( @cases ) {
    my ($val,$expected_status) = @$case;

    eval { assert_nonempty( $val ) };
    my $desc = 'Checking ' . ($val // 'undef');

    if ( $expected_status eq FAIL ) {
        like( $@, qr/Assertion.+failed/, $desc );
    }
    else {
        is( $@, '', $desc );
    }
}

NOT_AN_ARRAY: {
    throws_ok( sub { assert_nonempty( 27 ) }, qr/Assertion failed!.+Argument is not a hash or array\./sm );
}

BLESSED_ARRAY: {
    my $array_object = bless( [], 'WackyPackage' );
    throws_ok( sub { assert_nonempty( $array_object, 'Flooble' ) }, qr/\QAssertion (Flooble) failed!\E.+Array contains 0 elements\./sm );

    push( @{$array_object}, 14 );
    lives_ok( sub { assert_nonempty( $array_object ) } );
}

BLESSED_HASH: {
    my $hash_object = bless( {}, 'WackyPackage' );
    throws_ok( sub { assert_nonempty( $hash_object, 'Flargle' ) }, qr/\QAssertion (Flargle) failed!\E.+Hash contains 0 keys\./sm );

    $hash_object->{foo} = 14;
    lives_ok( sub { assert_nonempty( $hash_object ) } );
}


exit 0
