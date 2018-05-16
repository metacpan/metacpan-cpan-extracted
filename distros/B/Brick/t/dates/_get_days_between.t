#!/usr/bin/perl
use strict;

use Test::More 'no_plan';

use_ok( 'Brick::Dates' );
use_ok( 'Brick::Bucket' );

use lib qw( t/lib );
use_ok( 'Mock::Bucket' );

my $bucket = Mock::Bucket->new;
isa_ok( $bucket, 'Mock::Bucket' );
isa_ok( $bucket, Mock::Bucket->bucket_class );

can_ok( $bucket, '_get_days_between' );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# With two good dates, ascending
# SHOULD WORK, returns positive number

{
my $days = $bucket->_get_days_between( "20070101", "20070103" );

is( $days, 2, "Got one day between good dates, ascending" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# With two good dates, descending
# SHOULD WORK, returns negative number

{
my $days = $bucket->_get_days_between( "20070101", "20060101" );

is( $days, -365, "Got one day between good dates, descending" );
}
