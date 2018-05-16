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

can_ok( $bucket, '_is_even_number' );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#
{
my $sub = $bucket->_is_even_number();

isa_ok( $sub, ref sub {}, "_is_even_number returns a code ref" );


my $result = $sub->( { field => 4 } );
is( $result, 1, "Even number validates" );

$result = $sub->( { field => 3 } );

is( $result, 0, "Result fails (as expected)" );
ok( ! $@, "Failure isn't fatal" );
}
