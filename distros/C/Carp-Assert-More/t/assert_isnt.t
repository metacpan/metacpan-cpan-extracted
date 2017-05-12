#!perl -Tw

use warnings;
use strict;

use Test::More tests => 8;

use Carp::Assert::More;

use Test::Exception;

lives_ok   { assert_isnt( 4, 3 ) }      "4 is not 3";
lives_ok   { assert_isnt( undef, "" ) } "Undef is not space";
lives_ok   { assert_isnt( "", undef ) } "Space is not undef";

throws_ok    { assert_isnt( undef, undef ) }    qr/Assertion.+failed/,  "Undef only matches undef";
throws_ok    { assert_isnt( "a", "a" ) }        qr/Assertion.+failed/,  "a is a";
throws_ok    { assert_isnt( 4, 4 )      }       qr/Assertion.+failed/,  "4 is 4";
throws_ok    { assert_isnt( "", "" ) }          qr/Assertion.+failed/,  "space is space";
throws_ok    { assert_isnt( "14", 14 ) }        qr/Assertion.+failed/,  "14 is 14 as strings";
