#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;
use Test::Exception;

use lib 't';

$| = 1;

use MyTestClass;
use MyOtherTestClass;

# in a nearby piece of code...

lives_ok { MyTestClass->foo( 'fooval' ) } 'set val';

like( MyTestClass->foo, qr(^fooval$), 'retrieved val' );

like( MyOtherTestClass->foo, qr(^fooval$), 'retrieved val from subclass' );

lives_ok { MyOtherTestClass->foo( 'barval' ) } 'set val in subclass';

like( MyOtherTestClass->foo, qr(^barval$), 'retrieved new val from subclass' );

like( MyTestClass->foo, qr(^fooval$), 'retrieved original val from base class' );


