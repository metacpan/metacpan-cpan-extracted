#!perl

use warnings;
use strict;

use Test::More tests => 14;
use Test::Exception;

use Carp::Assert::More;

use constant PASS => 1;
use constant FAIL => 0;

my @cases = (
    [ 0         => FAIL ],
    [ 'foo'     => FAIL ],
    [ undef     => FAIL ],
    [ {}        => PASS ],
    [ []        => PASS ],
    [ {foo=>1}  => FAIL ],
    [ [1,2,3]   => FAIL ],
);

for my $case ( @cases ) {
    my ($val,$expected_status) = @$case;

    eval { assert_empty( $val ) };
    my $desc = 'Checking  ' . ($val // 'undef');

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
    lives_ok( sub { assert_empty( $array_object ) } );

    push( @{$array_object}, 14 );
    throws_ok( sub { assert_empty( $array_object, 'Flooble' ) }, qr/\QAssertion (Flooble) failed!\E.+Array contains 1 element\./sm );

    push( @{$array_object}, 43, 'Q' );
    throws_ok( sub { assert_empty( $array_object, 'Flooble' ) }, qr/\QAssertion (Flooble) failed!\E.+Array contains 3 elements\./sm );
}

BLESSED_HASH: {
    my $hash_object = bless( {}, 'WackyPackage' );
    lives_ok( sub { assert_empty( $hash_object ) } );

    $hash_object->{foo} = 14;
    throws_ok( sub { assert_empty( $hash_object, 'Flargle' ) }, qr/\QAssertion (Flargle) failed!\E.+Hash contains 1 key\./sm );

    $hash_object->{blu} = 28;
    $hash_object->{Q} = 47;
    throws_ok( sub { assert_empty( $hash_object, 'Flargle' ) }, qr/\QAssertion (Flargle) failed!\E.+Hash contains 3 keys\./sm );
}


exit 0;
