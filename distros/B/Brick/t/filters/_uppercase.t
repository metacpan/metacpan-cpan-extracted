#!/usr/bin/perl

use Test::More 'no_plan';

use_ok( 'Brick::Filters' );
use_ok( 'Brick::Bucket' );

use lib qw( t/lib );
use_ok( 'Mock::Bucket' );

my $bucket = Mock::Bucket->new;
isa_ok( $bucket, 'Mock::Bucket' );
isa_ok( $bucket, Mock::Bucket->bucket_class );

my $sub = $bucket->_uppercase( { filter_fields => [ qw(string string1 string2) ] } );

isa_ok( $sub, ref sub {}, "_uppercase returns a code ref" );


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $input = {
	string      => "Buster",
	leave_alone => "Mimi Bean",
	};

like( $input->{string},      qr/[a-z]/, "'string' has lowercase" );
like( $input->{leave_alone}, qr/[a-z]/, "'leave_alone' has lowercase" );

my $result = eval {
	$sub->( $input )
	};

ok( defined $result, "Result succeeds" );
diag( "Eval error: $@" ) unless defined $result;

like( $input->{string},      qr/\A[A-Z]+\z/, "'string' has no lowercase after filter" );
like( $input->{leave_alone}, qr/[a-z]/, "'leave_alone' still has lowercase after filter" );

ok( ! exists $input->{string1}, "Does not create missing field" );
ok( ! exists $input->{string2}, "Does not create missing field" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
{
my $input = {
	string1  => "Buster Bean",
	string2  => "Mimi Bean",
	};

like( $input->{string1}, qr/[a-z]/, "'string1' has lowercase" );
like( $input->{string2}, qr/[a-z]/, "'string2' has lowercase" );

my $result = eval {
	$sub->( $input )
	};

ok( defined $result, "Result succeeds" );
diag( "Eval error: $@" ) unless defined $result;

like( $input->{string1}, qr/\A[A-Z\s]+\z/, "'string1' has no lowercase after filter" );
like( $input->{string2}, qr/\A[A-Z\s]+\z/, "'string2' has no lowercase after filter" );

ok( ! exists $input->{string}, "Does not create missing field" );
}
