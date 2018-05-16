#!/usr/bin/perl

use Test::More 'no_plan';

use_ok( 'Brick::General' );
use_ok( 'Brick::Bucket' );

use lib qw( t/lib );
use_ok( 'Mock::Bucket' );

my $bucket = Mock::Bucket->new;
isa_ok( $bucket, 'Mock::Bucket' );
isa_ok( $bucket, Mock::Bucket->bucket_class );

can_ok( $bucket, '_numeric_equal_or_greater_than' );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
{
my $sub = $bucket->_numeric_equal_or_greater_than(
	{
	field   => 'n',
	minimum => 10,
	}
	);

isa_ok( $sub, ref sub {}, "_numeric_equal_or_greater_than returns a code ref" );


my $result = $sub->( { n => 11 } );
is( $result, 1, "Greater number validates" );

$result = $sub->( { n => 10 } );
is( $result, 1, "Equal number validates" );

$result = eval { $sub->( { n => 9 } ) };

is( $result, undef, "Result fails (as expected)" );
ok( $@, "Failure is fatal" );
}
