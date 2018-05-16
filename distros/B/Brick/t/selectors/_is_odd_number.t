#!/usr/bin/perl
use strict;

use Test::More 'no_plan';

use_ok( 'Brick::General' );
use_ok( 'Brick::Bucket' );

use lib qw( t/lib );
use_ok( 'Mock::Bucket' );

my $bucket = Mock::Bucket->new;
isa_ok( $bucket, 'Mock::Bucket' );
isa_ok( $bucket, Mock::Bucket->bucket_class );

can_ok( $bucket, '_is_odd_number' );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
{
my $sub = $bucket->_is_odd_number();

isa_ok( $sub, ref sub {}, "_is_odd_number returns a code ref" );


my $result = $sub->( { field => 7 } );
is( $result, 1, "Odd number validates" );

$result = $sub->( { field => 1234 } );

is( $result, 0, "Result fails (as expected)" );
ok( ! $@, "Failure isn't fatal" );
}
