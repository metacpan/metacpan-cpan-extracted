#!perl -w

use strict;
use Test::More tests => 3;

# Use
use_ok("Cal::DAV");

# Wrong instantiation
my $cal;
is( eval { $cal = Cal::DAV->new() }, undef, "Wrong instantiation");

# Right instantiation
ok($cal = Cal::DAV->new(user => 'foo', pass => 'pass', url => 'http://example.com'), "Right instantiation");
