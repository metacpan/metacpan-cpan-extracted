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
    $val = "undef" if !defined($val);
    my $desc = "Checking \"$val\"";

    if ( $expected_status eq FAIL ) {
        like( $@, qr/Assertion.+failed/, $desc );
    } else {
        is( $@, "", $desc );
    }
}

throws_ok( sub { assert_nonempty( 27 ) }, qr/Not an array or hash reference/ );

BLESSED_ARRAY: {
    my $array_object = bless( [], 'WackyPackage' );
    throws_ok( sub { assert_nonempty( $array_object, 'Flooble' ) }, qr/\QAssertion (Flooble) failed!/ );

    push( @{$array_object}, 14 );
    lives_ok( sub { assert_nonempty( $array_object ) } );
}

BLESSED_HASH: {
    my $hash_object = bless( {}, 'WackyPackage' );
    throws_ok( sub { assert_nonempty( $hash_object, 'Flargle' ) }, qr/\QAssertion (Flargle) failed!/ );

    $hash_object->{foo} = 14;
    lives_ok( sub { assert_nonempty( $hash_object ) } );
}
