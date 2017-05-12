#!/usr/bin/perl

use Test::More 'no_plan';

use_ok( 'Brick::Filters' );
use_ok( 'Brick::Bucket' );

use lib qw( t/lib );
use_ok( 'Mock::Bucket' );

my $bucket = Mock::Bucket->new;
isa_ok( $bucket, 'Mock::Bucket' );
isa_ok( $bucket, Mock::Bucket->bucket_class );

my $sub = $bucket->_lowercase( { filter_fields => [ qw(string string1 string2) ] } );
	
isa_ok( $sub, ref sub {}, "_lowercase returns a code ref" );


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $input = { 
	string      => "Buster",
	leave_alone => "Mimi Bean",
	};

like( $input->{string},      qr/[A-Z]/, "'string' has uppercase" );
like( $input->{leave_alone}, qr/[A-Z]/, "'leave_alone' has uppercase" );

my $result = eval { 
	$sub->( $input ) 
	}; 
	
ok( defined $result, "Result succeeds" );
diag( "Eval error: $@" ) unless defined $result;

like( $input->{string},      qr/\A[a-z\s]+\z/, "'string' has no uppercase after filter" );
like( $input->{leave_alone}, qr/[A-Z]/, "'leave_alone' still has uppercase after filter" );

ok( ! exists $input->{string1}, "Does not create missing field" );
ok( ! exists $input->{string2}, "Does not create missing field" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $input = { 
	string1  => "Buster Bean",
	string2  => "Mimi Bean",
	};

like( $input->{string1}, qr/[A-Z]/, "'string1' has uppercase" );
like( $input->{string2}, qr/[A-Z]/, "'string2' has uppercase" );

my $result = eval { 
	$sub->( $input ) 
	}; 
	
ok( defined $result, "Result succeeds" );
diag( "Eval error: $@" ) unless defined $result;

like( $input->{string1}, qr/\A[a-z\s]+\z/, "'string1' has no uppercase after filter" );
like( $input->{string2}, qr/\A[a-z\s]+\z/, "'string2' has no uppercase after filter" );

ok( ! exists $input->{string}, "Does not create missing field" );
}