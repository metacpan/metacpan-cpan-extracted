#!/usr/bin/env perl
use strict;
use warnings;
use lib '../lib';
use blib;

use Test::More tests => 2;
note( "Testing B::CodeLines $B::CodeLines::VERSION" );

BEGIN {
use_ok( 'B::CodeLines' );
}

ok(defined($B::CodeLines::VERSION), 
   "\$B::CodeLines::VERSION number is set");
