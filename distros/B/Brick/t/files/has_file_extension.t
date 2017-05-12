#!/usr/bin/perl
use strict;

use Test::More 'no_plan';

use_ok( 'Brick' );
use_ok( 'Brick::Bucket' );
use_ok( 'Brick::Files' );

ok( defined &Brick::Bucket::__caller_chain_as_list, "Caller sub is there" );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

my @good_extensions = qw(jpg png gif);
my @bad_extensions  = qw(eps jpeg xls);

my $sub = Brick::Bucket::has_file_extension(
	bless( {}, Brick->bucket_class ),
	{
	extensions => [ @good_extensions ],
	field      => 'upload_filename',
	name       => 'Image file checker',
	}
	);
	
isa_ok( $sub, ref sub {}, "I get back a sub" );


foreach my $extension ( @good_extensions )
	{
	my $result = $sub->(
		{
		upload_filename => "foo.$extension",
		}
		);
		
	ok( $result, "Sub returns true for good extension" );
	}


foreach my $extension ( @bad_extensions )
	{
	my $result = eval {
		$sub->(
			{
			upload_filename => "foo.$extension",
			}
			)
		};
		
	ok( ! defined $result, "Sub returns false for bad extension" );
	ok( $@, "\$@ set for bad extension" );
	}