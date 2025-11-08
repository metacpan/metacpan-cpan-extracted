#!/usr/bin/perl -w

## no critic

use warnings;
use strict;

use lib qw(. lib);

use Carp;

use Data::Dumper;
use Digest::MD5::File qw(file_md5_hex);
use English           qw(-no_match_vars);
use File::Temp        qw( tempfile );
use S3TestUtils       qw(:constants :subs);
use Test::More;
use XML::Simple qw{XMLin};

my $host = set_s3_host();

if ( !$ENV{'AMAZON_S3_EXPENSIVE_TESTS'} ) {
  plan skip_all => 'Testing this module for real costs money.';
} ## end if ( !$ENV{'AMAZON_S3_EXPENSIVE_TESTS'...})
else {
  plan tests => 6;
}

use_ok('Amazon::S3');
use_ok('Amazon::S3::Bucket');

my $s3 = get_s3_service($host);

my $bucket_name = make_bucket_name();

my $bucket_obj = create_bucket( $s3, $bucket_name );

ok( ref $bucket_obj, 'created bucket - ' . $bucket_name );

if ( $EVAL_ERROR || !$bucket_obj ) {
  BAIL_OUT( $s3->err . ": " . $s3->errstr );
} ## end if ( $EVAL_ERROR || !$bucket_obj)

my $id;
my $key = 'big-object-1';

########################################################################
subtest 'list-multipart-uploads' => sub {
########################################################################

  my $upload_list = list_multipart_uploads($bucket_obj);

  ok( !defined $upload_list, 'no in-progress uploads' )
    or diag( Dumper( [$upload_list] ) );

  $id = partial_upload( $key, $bucket_obj );

  $upload_list = list_multipart_uploads($bucket_obj);

  ok( $upload_list->{UploadId} eq $id, 'UploadId eq $id' );
};

########################################################################
subtest 'abort-multipart-upload' => sub {
########################################################################

  $bucket_obj->abort_multipart_upload( $key, $id );

  my $upload_list = list_multipart_uploads($bucket_obj);

  ok( !defined $upload_list, 'aborted upload' );
};

########################################################################
subtest 'abort-on-error' => sub {
########################################################################
  my $id = $bucket_obj->initiate_multipart_upload($key);

  my $part_list = {};

  my $part = 0;
  my $data = 'x' x ( 1024 * 1024 * 1 ); # should be too small

  # do this twice...
  foreach ( 0 .. 1 ) {
    my $etag
      = $bucket_obj->upload_part_of_multipart_upload( $key, $id, ++$part,
      $data, length $data );

    $part_list->{$part} = $etag;
  }

  eval { $bucket_obj->complete_multipart_upload( $key, $id, $part_list ); };

  ok( $EVAL_ERROR =~ /Bad Request/i, 'abort-on-error successful' )
    or diag( Dumper( [ $EVAL_ERROR, $id ] ) );

  $bucket_obj->abort_multipart_upload( $key, $id );
};

########################################################################

$bucket_obj->delete_bucket()
  or diag( $s3->errstr );

########################################################################
sub partial_upload {
########################################################################
  my ( $key, $bucket_obj, $size_in_mb ) = @_;

  my $id     = $bucket_obj->initiate_multipart_upload($key);
  my $length = ( $size_in_mb || 5 ) * 1024 * 1024;

  my $data = 'x' x $length;

  my $etag
    = $bucket_obj->upload_part_of_multipart_upload( $key, $id, 1, $data,
    $length );

  return $id;
}

########################################################################
sub list_multipart_uploads {
########################################################################
  my ($bucket_obj) = @_;

  my $xml = $bucket_obj->list_multipart_uploads;

  ok( $xml =~ /^</xms, 'is xml result' );

  my $uploads = XMLin( $xml, KeepRoot => $TRUE );

  isa_ok( $uploads, 'HASH', 'made a hash object' )
    or diag($uploads);

  ok( defined $uploads->{ListMultipartUploadsResult},
    'looks like a results object' )
    or diag($xml);

  my $upload_list = $uploads->{ListMultipartUploadsResult}->{Upload};

  return $upload_list;
}

1;
