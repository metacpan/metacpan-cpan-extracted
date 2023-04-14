#!/usr/bin/perl -w

## no critic

use warnings;
use strict;

use lib qw( . lib);

use Carp;

use Data::Dumper;
use Digest::MD5::File qw(file_md5_hex);
use English           qw{-no_match_vars};
use File::Temp        qw{ tempfile };
use Test::More;

use S3TestUtils qw(:constants :subs);

my $host = set_s3_host();

if ( !$ENV{'AMAZON_S3_EXPENSIVE_TESTS'} ) {
  plan skip_all => 'Testing this module for real costs money.';
}
else {
  plan tests => 7;
}

use_ok('Amazon::S3');
use_ok('Amazon::S3::Bucket');

my $s3 = get_s3_service($host);

if ( !$s3 ) {
  BAIL_OUT('could not initialize s3 object');
}

my $bucket_name = make_bucket_name();
my $bucket_obj  = create_bucket( $s3, $bucket_name );

ok( ref $bucket_obj, 'created bucket - ' . $bucket_name );

if ( $EVAL_ERROR || !$bucket_obj ) {
  BAIL_OUT( $s3->err . ": " . $s3->errstr );
} ## end if ( $EVAL_ERROR || !$bucket_obj)

########################################################################
subtest 'multipart-manual' => sub {
########################################################################
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

########################################################################
subtest 'multipart-file' => sub {
########################################################################
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

########################################################################
subtest 'multipart-2-parts' => sub {
########################################################################
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

########################################################################
subtest 'multipart-callback' => sub {
########################################################################
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

########################################################################

$bucket_obj->delete_bucket()
  or diag( $s3->errstr );

1;
