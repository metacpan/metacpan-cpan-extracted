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
    [ {}        => PASS ],
    [ []        => PASS ],
    [ {foo=>1}  => FAIL ],
    [ [1,2,3]   => FAIL ],
);

for my $case ( @cases ) {
    my ($val,$expected_status) = @$case;

    eval { assert_empty( $val ) };
    $val = "undef" if !defined($val);
    my $desc = "Checking \"$val\"";

    if ( $expected_status eq FAIL ) {
        like( $@, qr/Assertion.+failed/, $desc );
    } else {
        is( $@, "", $desc );
    }
}

throws_ok( sub { assert_empty( 27 ) }, qr/Not an array or hash reference/ );

BLESSED_ARRAY: {
    my $array_object = bless( [], 'WackyPackage' );
    lives_ok( sub { assert_empty( $array_object ) } );

    push( @{$array_object}, 14 );
    throws_ok( sub { assert_empty( $array_object, 'Flooble' ) }, qr/\QAssertion (Flooble) failed!/ );
}

BLESSED_HASH: {
    my $hash_object = bless( {}, 'WackyPackage' );
    lives_ok( sub { assert_empty( $hash_object ) } );

    $hash_object->{foo} = 14;
    throws_ok( sub { assert_empty( $hash_object, 'Flargle' ) }, qr/\QAssertion (Flargle) failed!/ );
}
