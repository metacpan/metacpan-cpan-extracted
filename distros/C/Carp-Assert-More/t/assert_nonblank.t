#!perl -Tw

use warnings;
use strict;

use Test::More tests => 7;

use Test::Exception;

use Carp::Assert::More;

lives_ok( sub { assert_nonblank( 3 ) } );
lives_ok( sub { assert_nonblank( 0 ) } );

throws_ok( sub { assert_nonblank( '' ) }, qr/Assertion failed!/, q{'' is blank, with no message} );
throws_ok( sub { assert_nonblank( '', 'flooble' ) }, qr/\QAssertion (flooble) failed!/, q{'' is blank, with message} );

throws_ok( sub { assert_nonblank( undef ) }, qr/Assertion failed!/, q{undef is blank, with no message} );
throws_ok( sub { assert_nonblank( undef, 'bargle' ) }, qr/\QAssertion (bargle) failed!/, q{undef is blank, with message} );

throws_ok( sub {
    my $scalar = "Blah blah";
    my $ref = \$scalar;
    assert_nonblank( $ref, 'wango' );
}, qr/\QAssertion (wango) failed!/, 'Testing scalar ref' );
