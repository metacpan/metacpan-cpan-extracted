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

can_ok( $bucket, '_is_YYYYMMDD_date_format' );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# With good date
# SHOULD WORK, returns true

{
my $sub = $bucket->_is_YYYYMMDD_date_format( { field => 'date' } );

isa_ok( $sub, ref sub {}, "_is_YYYYMMDD_date_format returns sub" );

ok(
	eval { $sub->( { date => 20070415 } ) },
	"Good date returns true"
	);
	
ok(
	! eval { $sub->( { date => 2007045 } ) },
	"Bad date returns false"
	);
	
}
