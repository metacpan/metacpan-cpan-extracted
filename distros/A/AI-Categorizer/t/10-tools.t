#!/usr/bin/perl -w

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use strict;
use Test;
BEGIN { 
  plan tests => 10;
};

use AI::Categorizer::Util qw(random_elements binary_search);
ok(1);

# Test random_elements()
my @x = ('a'..'j');
my @y = random_elements(\@x, 3);
ok @y, 3;
ok $y[0] =~ /^[a-j]$/;

@y = random_elements(\@x, 7);
ok @y, 7;
ok $y[0] =~ /^[a-j]$/;

# Test binary_search()
@x = (0,1,2,3,4,6,7,8);
ok binary_search(\@x,  5), 5;
ok binary_search(\@x, -1), 0;
ok binary_search(\@x,  9), 8;

@x = ();
ok binary_search(\@x,  1), 0;
ok binary_search(\@x, -1), 0;
