#!/usr/bin/perl
use strict;

use Test::More 'no_plan';

use File::Spec;

use_ok( 'Brick' );
use_ok( 'Brick::Files' );

use lib qw( t/lib );
use_ok( 'Mock::Bucket' );

my $bucket = Mock::Bucket->new;
isa_ok( $bucket, 'Mock::Bucket' );
isa_ok( $bucket, Mock::Bucket->bucket_class );

ok( defined &Brick::Bucket::is_clamav_clean, "is_clamav_clean sub is there");
#can_ok( $bucket, 'is_clamav_clean',  "can is_clamav_clean" );

ok( $bucket->can( 'is_clamav_clean' ), "can is_clamav_clean" );
