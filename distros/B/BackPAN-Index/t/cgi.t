#!perl

# Test to make sure CGI.pm is handled correctly

use strict;
use warnings;

use lib 't/lib';

use Test::More tests => 1;
use TestUtils;

my $p = new_backpan();

my $releases = $p->releases("CGI");
cmp_ok $releases->count, '>=', 140;
