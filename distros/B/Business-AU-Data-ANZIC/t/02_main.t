#!/usr/bin/perl

BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 2;
use Business::AU::Data::ANZIC;

# Get a basic io handle
my $handle = Business::AU::Data::ANZIC->get('IO::File');
isa_ok( $handle, 'IO::File' );

# Get a Parse::CSV object
my $parser = Business::AU::Data::ANZIC->get('Parse::CSV');
isa_ok( $parser, 'Parse::CSV' );
