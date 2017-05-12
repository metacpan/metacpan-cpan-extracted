#!/usr/bin/env perl
# -*- Perl -*-
use warnings;
use Test::More;
use rlib '../lib';
use Test::More tests => 2;
note( "Testing Array::Columnize::VERSION" );
BEGIN {
use_ok( Array::Columnize );
}
use strict;

ok(defined($Array::Columnize::VERSION), 
   "\$Array::Columnize::VERSION number is set");

