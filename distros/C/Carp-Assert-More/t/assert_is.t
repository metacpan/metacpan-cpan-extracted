#!perl -Tw

use warnings;
use strict;

use Test::More tests => 8;

use Carp::Assert::More;

use Test::Exception;

throws_ok   { assert_is( 4, 3 ) }       qr/Assertion.*failed/, "4 is not 3";
throws_ok   { assert_is( undef, "" ) }  qr/Assertion.*failed/, "Undef is not space";
throws_ok   { assert_is( "", undef ) }  qr/Assertion.*failed/, "Space is not undef";

lives_ok    { assert_is( undef, undef ) }   "Undef only matches undef";
lives_ok    { assert_is( "a", "a" ) }       "a is a";
lives_ok    { assert_is( 4, 4 ) }           "4 is 4";
lives_ok    { assert_is( "", "" ) }         "space is space";
lives_ok    { assert_is( "14", 14 ) }       "14 is 14 as strings";
