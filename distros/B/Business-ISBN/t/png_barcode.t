#!/usr/bin/perl
use strict;

use Test::More;

my $loaded  = eval { require GD::Barcode::EAN13 };

my $GD_okay = eval { GD::Font->Small };

unless( $loaded )
	{
	plan( skip_all => "You need GD::Barcode::EAN13 to make barcodes" );
	}
elsif( not $GD_okay )
	{
	# This is something that should be caught in GD::Barcode::EAN13
	plan( skip_all => "GD is missing GD::Font->Small. Can't continue." );
	}
else
	{
	plan( tests => 8 );
	
	my $class = 'Business::ISBN';
	
	use_ok( $class );
	
	ok( defined &Business::ISBN::png_barcode, "Method defined" );
		
	foreach my $num ( qw( 0596527241 9780596527242 ) )
		{
		my $isbn = Business::ISBN->new( $num );
		isa_ok( $isbn, $class );
		
		ok( $isbn->is_valid, "Valid ISBN" );
						
		my $png  = eval { $isbn->png_barcode };
		my $at = $@;
		ok( defined $png, "PNG defined for $num" );
		diag( "Eval error for $num: $at" ) if length $at;
		}
	}