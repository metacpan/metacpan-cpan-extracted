#!/usr/bin/perl
use strict;

use Test::More 'no_plan';

use_ok( 'Brick::Bucket' );

ok( defined &Brick::Bucket::__compose_satisfy_all,
	"__compose_satisfy_all defined"
	);
	
ok( defined &Brick::Bucket::__and,
	"__and defined"
	);
		
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
my $false_sub = sub { 0 };
my $true_sub  = sub { 1 };
my $empty_string_sub = sub { die {} };
my $undef_sub = sub { return  };
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
foreach my $sub_name ( qw(__compose_satisfy_all __and) )
	{
	# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
	# try it with one sub
	{
	my $sub = $bucket->$sub_name( $true_sub );
	isa_ok( $sub, ref sub {}, "$sub_name returns a code ref" );
	
	my $result = eval { $sub->({}) };
	is( $result, 1, "Satisfied one test (that's good)" );
	}
	
	# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
	# try it with two subs
	{
	my $sub = $bucket->$sub_name( $false_sub, $true_sub );
	isa_ok( $sub, ref sub {}, "$sub_name returns a code ref" );
	
	my $result = eval { $sub->({}) };
	is( $result, 1, "Satisfied two tests (that's good)" );
	}
	
	# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
	# try it with three subs
	{
	my $sub = $bucket->$sub_name( 
		$false_sub, $undef_sub, $true_sub );
	isa_ok( $sub, ref sub {}, "$sub_name returns a code ref" );
	
	my $result = eval { $sub->({}) };
	is( $result, 1, "Satisfied three tests (that's good)" );
	}
	
	# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
	# try it with some subs that die
	{
	my $sub = $bucket->$sub_name( 
		$false_sub, $undef_sub, $empty_string_sub, $true_sub );
	isa_ok( $sub, ref sub {}, "$sub_name returns a code ref" );
	
	my $result = eval { $sub->({}) };
	ok( ! $result, "Failed something (that's bad)" );
	}
	
	}
