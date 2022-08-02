#!/usr/bin/perl -w

## no critic

use warnings;
use strict;

use lib 'lib';

use Carp;

use Data::Dumper;
use Digest::MD5::File qw(file_md5_hex);
use English qw{-no_match_vars};
use File::Temp qw{ tempfile };
use Test::More;

my $host;

if ( exists $ENV{AMAZON_S3_LOCALSTACK} ) {
  $host = 'localhost:4566';

  $ENV{'AWS_ACCESS_KEY_ID'}     = 'test';
  $ENV{'AWS_ACCESS_KEY_SECRET'} = 'test';

  $ENV{'AMAZON_S3_EXPENSIVE_TESTS'} = 1;

} ## end if ( exists $ENV{AMAZON_S3_LOCALSTACK...})
else {
  $host = $ENV{AMAZON_S3_HOST};
} ## end else [ if ( exists $ENV{AMAZON_S3_LOCALSTACK...})]

my $secure = $host ? 0 : 1;

# do not use DNS bucket names for testing if a mocking service is used
# override this by setting AMAZON_S3_DNS_BUCKET_NAMES to any value
# your tests may fail unless you have DNS entry for the bucket name
# e.g 127.0.0.1 net-amazon-s3-test-test.localhost

my $dns_bucket_names
  = ( $host && !exists $ENV{AMAZON_S3_DNS_BUCKET_NAMES} ) ? 0 : 1;

my $aws_access_key_id     = $ENV{'AWS_ACCESS_KEY_ID'};
my $aws_secret_access_key = $ENV{'AWS_ACCESS_KEY_SECRET'};
my $token                 = $ENV{'AWS_SESSION_TOKEN'};

if ( !$ENV{'AMAZON_S3_EXPENSIVE_TESTS'} ) {
  plan skip_all => 'Testing this module for real costs money.';
} ## end if ( !$ENV{'AMAZON_S3_EXPENSIVE_TESTS'...})
else {
  plan tests => 7;
}

use_ok('Amazon::S3');
use_ok('Amazon::S3::Bucket');

my $s3;

if ( $ENV{AMAZON_S3_CREDENTIALS} ) {
  require Amazon::Credentials;

  $s3 = Amazon::S3->new(
    { credentials      => Amazon::Credentials->new,
      host             => $host,
      secure           => $secure,
      dns_bucket_names => $dns_bucket_names,
      level            => $ENV{DEBUG} ? 'trace' : 'error',
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
      host                  => $host,
      secure                => $secure,
      dns_bucket_names      => $dns_bucket_names,
      level                 => $ENV{DEBUG} ? 'trace' : 'error',
    }
  );
} ## end else [ if ( $ENV{AMAZON_S3_CREDENTIALS...})]

sub create_bucket {
  my ($bucket_name) = @_;

  $bucket_name = '/' . $bucket_name;
  my $bucket_obj
    = eval { return $s3->add_bucket( { bucket => $bucket_name } ); };

  return $bucket_obj;
}

my $bucket_obj = create_bucket sprintf 'net-amazon-s3-test-%s',
  lc $aws_access_key_id;

ok( ref $bucket_obj, 'created bucket' );

if ( $EVAL_ERROR || !$bucket_obj ) {
  BAIL_OUT( $s3->err . ": " . $s3->errstr );
} ## end if ( $EVAL_ERROR || !$bucket_obj)

subtest 'multipart-manual' => sub {
  my $key = 'big-object-1';

  my $id = $bucket_obj->initiate_multipart_upload($key);

  my $part_list = {};

  my $part = 0;
  my $data = 'x' x ( 1024 * 1024 * 5 ); # 5 MB part

  my $etag
    = $bucket_obj->upload_part_of_multipart_upload( $key, $id, ++$part, $data,
    length $data );

  $part_list->{$part} = $etag;

  $bucket_obj->complete_multipart_upload( $key, $id, $part_list );

  my $head = $bucket_obj->head_key($key);

  ok( $head, 'uploaded file' );

  ok( $head->{content_length} == 5 * 1024 * 1024, 'uploaded 1 part' )
    or diag( Dumper( [$head] ) );

  ok( $bucket_obj->delete_key($key) );
};

subtest 'multipart-file' => sub {
  my ( $fh, $file ) = tempfile();

  my $buffer = 'x' x ( 1024 * 1024 );

  # 11MB
  foreach ( 0 .. 10 ) {
    $fh->syswrite($buffer);
  }

  $fh->close;

  if ( !open( $fh, '<', $file ) ) {
    carp "could not open $file after writing";

    return;
  }

  my $key = 'big-object-2';

  $bucket_obj->upload_multipart_object( fh => $fh, key => $key );

  close $fh;

  my $head = $bucket_obj->head_key($key);

  ok( $head, 'uploaded file' );

  isa_ok( $head, 'HASH', 'head is a hash' );

  ok( $head->{content_length} == 11 * 1024 * 1024, 'uploaded all parts' );

  $bucket_obj->delete_key($key);

  unlink $file;
};

subtest 'multipart-2-parts' => sub {
  my $length = 1024 * 1024 * 7;

  my $data = 'x' x $length;

  my $key = 'big-object-3';

  $bucket_obj->upload_multipart_object(
    key  => $key,
    data => $data
  );

  my $head = $bucket_obj->head_key($key);

  isa_ok( $head, 'HASH', 'head is a hash' );

  ok( $head, 'uploaded data' );

  ok( $head->{content_length} == $length, 'uploaded all parts' );

  $bucket_obj->delete_key($key);
};

subtest 'multipart-callback' => sub {
  my $key = 'big-object-4';

  my @part = ( 5, 5, 5, 1 );
  my $size;

  $bucket_obj->upload_multipart_object(
    key      => $key,
    callback => sub {
      return ( q{}, 0 ) unless @part;

      my $length = shift @part;
      $length *= 1024 * 1024;

      $size += $length;

      my $data = 'x' x $length;

      return ( \$data, $length );
    }
  );

  my $head = $bucket_obj->head_key($key);

  isa_ok( $head, 'HASH', 'head is a hash' );

  ok( $head, 'uploaded data' );

  ok( $head->{content_length} == $size, 'uploaded all parts' );

  $bucket_obj->delete_key($key);
};

$bucket_obj->delete_bucket()
  or diag( $s3->errstr );

