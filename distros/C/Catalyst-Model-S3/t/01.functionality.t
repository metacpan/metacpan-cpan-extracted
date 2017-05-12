#!/usr/bin/perl -wT

use strict;
use warnings;

use Test::More tests => 3;
use lib qw( t/lib );


# Make sure the Catalyst app loads ok...
use_ok('TestApp');


# Check that the S3 model returns a valid Net::Amazon::S3 object...
my $s3 = TestApp->model('S3');
isa_ok( $s3, 'Net::Amazon::S3' );
can_ok( $s3, 'buckets' );


# If you've already tested and installed Net::Amazon::S3, there is no reason
# to run tests against the S3 server again.


1;
