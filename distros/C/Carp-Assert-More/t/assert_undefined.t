#!perl -T

use warnings;
use strict;

use Test::More tests => 4;

use Carp::Assert::More;

use Test::Exception;

throws_ok( sub { assert_undefined( 3, 'Fleegle' ); }, qr/\QAssertion (Fleegle) failed!/, '3 is defined' );
throws_ok( sub { assert_undefined( 0, 'Drooper' ); }, qr/\QAssertion (Drooper) failed!/, '0 is defined' );
throws_ok( sub { assert_undefined( '', 'Snork' ); }, qr/\QAssertion (Snork) failed!/, 'blank is defined' );
lives_ok(  sub { assert_undefined( undef ); }, '0 is undefined' );
