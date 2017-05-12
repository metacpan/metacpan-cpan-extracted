#!/usr/bin/perl

use Test::More 'no_plan';

use_ok( 'Brick::Filters' );
use_ok( 'Brick::Bucket' );

use lib qw( t/lib );
use_ok( 'Mock::Bucket' );

my $bucket = Mock::Bucket->new;
isa_ok( $bucket, 'Mock::Bucket' );
isa_ok( $bucket, Mock::Bucket->bucket_class );

my $sub = $bucket->_remove_whitespace( { filter_fields => [ qw(string string1 string2) ] } );
	
isa_ok( $sub, ref sub {}, "_remove_whitespace returns a code ref" );


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $input = { 
	string      => "Buster Bean",
	leave_alone => "Mimi Bean",
	};

like( $input->{string},      qr/\s/, "'string' has whitespace" );
like( $input->{leave_alone}, qr/\s/, "'leave_alone' has whitespace" );

my $result = eval { 
	$sub->( $input ) 
	}; 
	
ok( defined $result, "Result succeeds" );
diag( "Eval error: $@" ) unless defined $result;

like( $input->{string},      qr/\A\S+\z/, "'string' has no whitespace after filter" );
like( $input->{leave_alone}, qr/\s/, "'leave_alone' still has whitespace after filter" );

ok( ! exists $input->{string1}, "Does not create missing field" );
ok( ! exists $input->{string2}, "Does not create missing field" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $input = { 
	string1  => "Buster Bean",
	string2  => "Mimi Bean",
	};

like( $input->{string1}, qr/\s/, "'string1' has whitespace" );
like( $input->{string2}, qr/\s/, "'string2' has whitespace" );

my $result = eval { 
	$sub->( $input ) 
	}; 
	
ok( defined $result, "Result succeeds" );
diag( "Eval error: $@" ) unless defined $result;

like( $input->{string1}, qr/\A\S+\z/, "'string1' has no whitespace after filter" );
like( $input->{string2}, qr/\A\S+\z/, "'string2' has no whitespace after filter" );

ok( ! exists $input->{string}, "Does not create missing field" );
}