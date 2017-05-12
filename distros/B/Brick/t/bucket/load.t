#!/usr/bin/perl

use vars qw(@modules);

BEGIN {
	@modules = qw(
		Brick	
		Brick::Composers
		Mock::Bucket
		Mock::FooValidator
		Mock::BarValidator
	);
	}
	
use Test::More tests => 3;
use strict;

my @modules = qw(
	Brick::Composers
	);

foreach my $module ( @modules )
	{
	print "BAIL OUT!" unless use_ok( $module );
	}
	

# API shims
ok( defined &Brick::Bucket::add_to_pool );
ok( ! eval { Brick::Bucket->add_to_pool } );
