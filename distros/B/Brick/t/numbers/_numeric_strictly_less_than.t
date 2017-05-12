#!/usr/bin/perl

use Test::More 'no_plan';

use_ok( 'Brick::General' );
use_ok( 'Brick::Bucket' );

use lib qw( t/lib );
use_ok( 'Mock::Bucket' );

my $bucket = Mock::Bucket->new;
isa_ok( $bucket, 'Mock::Bucket' );
isa_ok( $bucket, Mock::Bucket->bucket_class );

can_ok( $bucket, '_numeric_strictly_less_than' );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
#
{
my $sub = $bucket->_numeric_strictly_less_than(
	{
	field   => 'n',
	maximum => 12,
	}
	);
	
isa_ok( $sub, ref sub {}, "_numeric_strictly_less_than returns a code ref" );


my $result = $sub->( { n => 7 } );
is( $result, 1, "Lesser number validates" );

$result = eval { $sub->( { n => 12 } ) };
ok( ! defined $result, "Equal number fails (as expected)" );
ok( $@, "Failure is fatal" );
isa_ok( $@, ref {} );

$result = eval { $sub->( { n => 19 } ) };

ok( ! defined $result, "Greater number fails (as expected)" );
ok( $@, "Failure is fatal" );
isa_ok( $@, ref {} );
}