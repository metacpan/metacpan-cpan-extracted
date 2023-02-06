#!/usr/bin/perl -w

## no critic

use warnings;
use strict;

use lib 'lib';

use English qw{-no_match_vars};

use Test::More;
use Data::Dumper;

my $aws_access_key_id     = $ENV{'AWS_ACCESS_KEY_ID'}     // 'foo';
my $aws_secret_access_key = $ENV{'AWS_ACCESS_KEY_SECRET'} // 'foo';
my $token                 = $ENV{'AWS_SESSION_TOKEN'};

my $host = $ENV{AMAZON_S3_HOST};

if ( !$ENV{'AMAZON_S3_EXPENSIVE_TESTS'} ) {
  plan skip_all => 'Testing this module for real costs money.';
} ## end if ( !$ENV{'AMAZON_S3_EXPENSIVE_TESTS'...})
else {
  plan tests => 16;
} ## end else [ if ( !$ENV{'AMAZON_S3_EXPENSIVE_TESTS'...})]

########################################################################
# BEGIN TESTS
########################################################################

use_ok('Amazon::S3');
use_ok('Amazon::S3::Bucket');

my $s3;

if ( $ENV{AMAZON_S3_CREDENTIALS} ) {
  require Amazon::Credentials;

  $s3 = Amazon::S3->new(
    { credentials => Amazon::Credentials->new,
      host        => $host,
      log_level   => $ENV{DEBUG} ? 'debug' : undef,
    }
  );
  ( $aws_access_key_id, $aws_secret_access_key, $token )
    = $s3->get_credentials;
} ## end if ( $ENV{AMAZON_S3_CREDENTIALS...})
else {
  $s3 = Amazon::S3->new(
    { aws_access_key_id     => $aws_access_key_id,
      aws_secret_access_key => $aws_secret_access_key,
      token                 => $token,
      debug                 => $ENV{DEBUG},
      host                  => $host,
      secure                => $host ? 0 : 1,         # if host then probably container
    }
  );
} ## end else [ if ( $ENV{AMAZON_S3_CREDENTIALS...})]

my $bucketname_raw = sprintf 'net-amazon-s3-test-%s', lc $aws_access_key_id;

my $bucketname = '/' . $bucketname_raw;

my $bucket_obj = eval { $s3->add_bucket( { bucket => $bucketname } ); };

if ( $EVAL_ERROR || !$bucket_obj ) {
  BAIL_OUT( $s3->err . ": " . $s3->errstr );
} ## end if ( $EVAL_ERROR || !$bucket_obj)

is( ref $bucket_obj, 'Amazon::S3::Bucket', 'created bucket' . $bucketname )
  or BAIL_OUT("could not create bucket $bucketname");

my $response = $bucket_obj->list
  or BAIL_OUT( $s3->err . ": " . $s3->errstr );

is( $response->{bucket}, $bucketname_raw, 'no bucket name in list response' )
  or do {
  diag( Dumper( [$response] ) );
  BAIL_OUT( Dumper [$response] );
  };

ok( !$response->{prefix}, 'no prefix in list response' );
ok( !$response->{marker}, 'no marker in list response' );

is( $response->{max_keys}, 1_000, 'max keys default = 1000' )
  or BAIL_OUT( Dumper [$response] );

is( $response->{is_truncated}, 0, 'is_truncated 0' );

is_deeply( $response->{keys}, [], 'no keys in bucket yet' )
  or BAIL_OUT( Dumper( [$response] ) );

foreach my $key ( 0 .. 9 ) {
  my $keyname = sprintf 'testing-%02d.txt', $key;
  my $value   = 'T';

  $bucket_obj->add_key( $keyname, $value );
} ## end foreach my $key ( 0 .. 9 )

subtest 'list_all' => sub {
  my $response = $bucket_obj->list_all;

  is( ref $response, 'HASH', 'response isa HASH' )
    or diag( Dumper( [$response] ) );

  is( ref $response->{keys}, 'ARRAY', 'keys element is an ARRAY' )
    or diag( Dumper( [$response] ) );

  is( @{ $response->{keys} }, 10, '10 keys returned' )
    or diag( Dumper( [$response] ) );

  foreach my $key ( @{ $response->{keys} } ) {
    is( ref $key, 'HASH', 'array element isa HASH' )
      or diag( Dumper( [$key] ) );

    like( $key->{key}, qr/testing-\d{2}.txt/, 'keyname' )
      or diag( Dumper( [$key] ) );

  } ## end foreach my $key ( @{ $response...})
};

subtest 'list' => sub {

  my $marker = '';
  my $iter   = 0; # so we don't loop forever if this is busted

  my @key_list;

  while ( $marker || !$iter ) {
    last if $iter++ > 5;

    $response = $bucket_obj->list(
      { 'max-keys' => 3,
        marker     => $marker,
        delimiter  => '/'
      }
    );

    if ( !$response ) {
      BAIL_OUT( $s3->err . ": " . $s3->errstr );
    } ## end if ( !$response )

    is( $response->{bucket}, $bucketname_raw, 'no bucket name' );

    ok( !$response->{prefix}, 'no prefix' )
      or diag( Dumper [$response] );

    is( $response->{max_keys}, 3, 'max-keys 3' );

    is( ref $response->{keys}, 'ARRAY' )
      or BAIL_OUT( Dumper( [$response] ) );

    push @key_list, @{ $response->{keys} };

    $marker = $response->{next_marker};
  } ## end while ( $marker || !$iter)

  is( @key_list, 10, 'got 10 keys' )
    or diag( Dumper( \@key_list ) );
};

subtest 'list-v2' => sub {

  my $marker = '';
  my $iter   = 0; # so we don't loop forever if this is busted

  my @key_list;

  while ( $marker || !$iter ) {
    last if $iter++ > 5;

    $response = $bucket_obj->list_v2(
      { 'max-keys' => 3,
        $marker ? ( 'marker' => $marker ) : (),
        delimiter => '/',
      }
    );

    if ( !$response ) {
      BAIL_OUT( $s3->err . ": " . $s3->errstr );
    } ## end if ( !$response )

    is( $response->{bucket}, $bucketname_raw, 'no bucket name' );

    ok( !$response->{prefix}, 'no prefix' )
      or diag( Dumper [$response] );

    is( $response->{max_keys}, 3, 'max-keys 3' );

    is( ref $response->{keys}, 'ARRAY' )
      or BAIL_OUT( Dumper( [$response] ) );

    push @key_list, @{ $response->{keys} };

    $marker = $response->{next_marker};
  } ## end while ( $marker || !$iter)

  is( @key_list, 10, 'got 10 keys' )
    or diag( Dumper( \@key_list ) );
};

$response = $s3->list_bucket_all( { bucket => $bucketname } );

is( ref $response,          'HASH', 'list_bucket_all response is a HASH' );
is( @{ $response->{keys} }, 10,     'got all 10 keys' );

$response = $s3->list_bucket_all_v2( { bucket => $bucketname } );
is( ref $response,          'HASH', 'list_bucket_all_v2 response is a HASH' );
is( @{ $response->{keys} }, 10,     'got all 10 keys' );

foreach my $key ( 0 .. 9 ) {
  my $keyname = sprintf 'testing-%02d.txt', $key;

  $bucket_obj->delete_key($keyname);
} ## end foreach my $key ( 0 .. 9 )

$bucket_obj->delete_bucket;

1;
