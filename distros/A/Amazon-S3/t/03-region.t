#!/usr/bin/perl -w

## no critic

use warnings;
use strict;

use lib qw(lib);

use English qw{-no_match_vars};

use Test::More;

plan tests => 7;

use_ok('Amazon::S3');

my $s3 = Amazon::S3->new(
  { aws_access_key_id     => 'test',
    aws_secret_access_key => 'test',
    log_level             => $ENV{DEBUG} ? 'debug' : undef,
  }
);

ok( $s3->region, 'us-east-1' );

is( $s3->host, 's3.us-east-1.amazonaws.com',
  'default host is s3.us-east-1.amazonaws.com' );

$s3 = Amazon::S3->new(
  { aws_access_key_id     => 'test',
    aws_secret_access_key => 'test',
    region                => 'us-west-2',
    log_level             => $ENV{DEBUG} ? 'debug' : undef,
  }
);

is( $s3->region, 'us-west-2', 'region is set' );

is( $s3->host, 's3.us-west-2.amazonaws.com',
  'host is modified during creation' );

$s3->region('us-east-1');

is( $s3->region, 'us-east-1', 'region is set' );

is( $s3->host, 's3.us-east-1.amazonaws.com',
  'host is modified when region changes' );

