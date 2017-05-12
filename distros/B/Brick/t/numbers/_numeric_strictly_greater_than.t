#!/usr/bin/perl

use Test::More 'no_plan';

use_ok( 'Brick::General' );
use_ok( 'Brick::Bucket' );

use lib qw( t/lib );
use_ok( 'Mock::Bucket' );

my $bucket = Mock::Bucket->new;
isa_ok( $bucket, 'Mock::Bucket' );
isa_ok( $bucket, Mock::Bucket->bucket_class );

can_ok( $bucket, '_numeric_strictly_greater_than' );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
#
{
my $sub = $bucket->_numeric_strictly_greater_than(
	{
	field   => 'n',
	minimum => 10,
	}
	);
	
isa_ok( $sub, ref sub {}, "_numeric_strictly_greater_than returns a code ref" );


my $result = $sub->( { n => 15 } );
is( $result, 1, "Greater number validates" );

$result = eval { $sub->( { n => 10 } ) };
ok( ! defined $result, "Equal number fails (as expected)" );
ok( $@, "Failure is fatal" );
isa_ok( $@, ref {} );

$result = eval { $sub->( { n => 9 } ) };

ok( ! defined $result, "Lesser number fails (as expected)" );
ok( $@, "Failure is fatal" );
isa_ok( $@, ref {} );
}