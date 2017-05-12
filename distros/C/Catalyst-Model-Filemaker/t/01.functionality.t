#!/usr/bin/perl -wT

use strict;
use warnings;

use Test::More tests => 3;
use lib qw( t/lib );


# Make sure the Catalyst app loads ok...
use_ok('TestApp');


# Check that the Filemaker model returns a valid Net::Filemaker::XML object...
my $fm = TestApp->model('Filemaker');
isa_ok( $fm, 'Net::FileMaker::XML::Database' );
can_ok( $fm, 'dbnames' );


# no more tests needed as you've already installed the N::F::X module


1;
