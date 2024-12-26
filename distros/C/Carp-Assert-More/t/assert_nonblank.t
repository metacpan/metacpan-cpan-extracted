#!perl

use warnings;
use strict;

use Test::More tests => 7;

use Test::Exception;

use Carp::Assert::More;

lives_ok( sub { assert_nonblank( 3 ) } );
lives_ok( sub { assert_nonblank( 0 ) } );

throws_ok( sub { assert_nonblank( '' ) }, qr/Assertion failed!.+Value is blank/sm, q{'' is blank, with no message} );
throws_ok( sub { assert_nonblank( '', 'flooble' ) }, qr/\QAssertion (flooble) failed!\E.+Value is blank/sm, q{'' is blank, with message} );

throws_ok( sub { assert_nonblank( undef ) }, qr/Assertion failed!.+Value is undef/sm, q{undef is blank, with no message} );
throws_ok( sub { assert_nonblank( undef, 'bargle' ) }, qr/\QAssertion (bargle) failed!\E.+Value is undef/sm, q{undef is blank, with message} );

throws_ok( sub {
    my $scalar = "Blah blah";
    my $ref = \$scalar;
    assert_nonblank( $ref, 'wango' );
}, qr/\QAssertion (wango) failed!\E.+Value is a reference to SCALAR/ms, 'Testing scalar ref' );


exit 0;
