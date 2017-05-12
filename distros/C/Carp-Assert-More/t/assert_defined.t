#!perl -T

use warnings;
use strict;

use Test::More tests => 4;

use Carp::Assert::More;

use Test::Exception;

lives_ok( sub { assert_defined( 3 ); }, '3 is defined' );
lives_ok( sub { assert_defined( 0 ); }, '0 is false but defined' );
lives_ok( sub { assert_defined( '' ); }, 'blank is false but defined' );
throws_ok( sub { assert_defined( undef, 'Flargle' ); }, qr/\QAssertion (Flargle) failed!/, 'undef is not defined' );
