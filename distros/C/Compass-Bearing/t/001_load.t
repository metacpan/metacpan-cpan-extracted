#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 2;

BEGIN { use_ok( 'Compass::Bearing' ); }

my $obj = Compass::Bearing->new;
isa_ok($obj, "Compass::Bearing");

