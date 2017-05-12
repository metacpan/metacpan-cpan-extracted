#!/usr/bin/perl
use strict;

use Test::More 'no_plan';

use_ok( 'Brick::Bucket' );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
ok( defined &Brick::Bucket::__compose_satisfy_none,
	"__compose_satisfy_none defined"
	);
	
ok( defined &Brick::Bucket::__none,
	"__none defined"
	);
	
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
my $false_sub = sub { die {} };
my $true_sub  = sub { 1 };
my $empty_string_sub = sub { die {} };
my $undef_sub = sub { die {}  };
my $die_sub   = sub { die {
	handler => 'die_sub',
	message => 'I die for no good reason other than I like it',
	} };


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
use lib qw( t/lib );
use_ok( 'Mock::Bucket' );

my $bucket = Mock::Bucket->new;
isa_ok( $bucket, 'Mock::Bucket' );
isa_ok( $bucket, Mock::Bucket->bucket_class );

# test both names
foreach my $sub_name ( qw(__compose_satisfy_none __none) )
	{
	# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
	# try it with one sub
	{
	my $sub = $bucket->$sub_name( $false_sub );
	isa_ok( $sub, ref sub {}, "$sub_name returns a code ref" );
	
	my $result = eval { $sub->({}) };
	is( $result, 1, "Satisfied no tests (that's good)" );
	}
	
	# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
	# try it with two subs
	{
	my $sub = $bucket->$sub_name( $false_sub, $undef_sub );
	isa_ok( $sub, ref sub {}, "$sub_name returns a code ref" );
	
	my $result = eval { $sub->({}) };
	is( $result, 1, "Satisfied no tests (that's good)" );
	}
	
	# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
	# try it with three subs
	{
	my $sub = $bucket->$sub_name( 
		$false_sub, $undef_sub, $empty_string_sub );
	isa_ok( $sub, ref sub {}, "$sub_name returns a code ref" );
	
	my $result = eval { $sub->({}) };
	is( $result, 1, "Satisfied no tests (that's good)" );
	}
	
	# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
	# try it with some subs that pass
	{
	my $sub = $bucket->$sub_name( 
		$false_sub, $undef_sub, $empty_string_sub, $true_sub );
	isa_ok( $sub, ref sub {}, "$sub_name returns a code ref" );
	
	my $result = eval { $sub->({}) };
	ok( ! $result, "Satisfied something (that's bad)" );
	}
	
	}
