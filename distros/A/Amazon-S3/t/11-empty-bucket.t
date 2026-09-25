#!/usr/bin/env perl

use strict;
use warnings;

use lib q(t/lib);

use Data::Dumper;
use English qw(-no_match_vars);
use S3TestUtils qw(:constants :subs);
use Test::More;

local $ENV{AMAZON_S3_LOCALSTACK}       = $TRUE;
local $ENV{AMAZON_S3_DNS_BUCKET_NAMES} = $FALSE;

my $host = eval { set_s3_host; };

if ( $EVAL_ERROR && $EVAL_ERROR !~ /unavailable/xsm ) {
  diag($EVAL_ERROR);
  BAIL_OUT("ERROR setting host...\n$EVAL_ERROR\ncannot continue\n");
}

plan skip_all => 'LocalStack unavailable'
  if $EVAL_ERROR && $EVAL_ERROR =~ /unavailable/xsm;

my $s3          = get_s3_service( $host, $TRUE );
my $bucket_name = "test-bucket-$PID";

########################################################################
subtest 'empty bucket' => sub {
########################################################################

  eval { $s3->add_bucket( { bucket => $bucket_name, } ); };

  my $bucketv2 = $s3->bucketv2( bucket => $bucket_name );

  $bucketv2->PutBucketVersioning( body => { VersioningConfiguration => { Status => 'Enabled' } } );

  my $obj = <<'END_OF_OBJECT';
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed at rutrum
mi. Pellentesque urna diam, mollis at ullamcorper a, aliquet eu
dolor. Sed a consequat sem. Aliquam a nunc sed enim vestibulum
scelerisque. Mauris leo eros, porta condimentum lobortis eget,
dignissim id nisl. Maecenas eleifend eros elit, nec sagittis magna
feugiat at. Morbi sed eleifend neque. Nulla sollicitudin dolor nec est
pharetra, nec blandit lorem auctor. Suspendisse et nunc orci. Aliquam
in elementum urna. Duis felis arcu, vestibulum eget malesuada eget,
convallis sit amet mi. In et fermentum massa. Etiam non lorem vitae
justo euismod semper nec id neque. Sed at posuere lectus. Proin
suscipit nisi vel turpis fermentum vestibulum.
END_OF_OBJECT

  my $bucket = $s3->bucket($bucket_name);
  $bucket->add_key( 'Lorem-Ipsum-Dolor.txt', $obj, { content_type => 'plain/text' } );

  # add another version
  $bucket->add_key( 'Lorem-Ipsum-Dolor.txt', $obj, { content_type => 'plain/text' } );

  # ...and another
  $bucket->add_key( 'Lorem-Ipsum-Dolor.txt', $obj, { content_type => 'plain/text' } );

  $bucket->delete_key('Lorem-Ipsum-Dolor.txt');

  my $rsp = eval { $s3->empty_bucket($bucket_name) };

  isa_ok( $rsp, 'HASH', 'response is a hash' );

  is( $rsp->{versions_deleted},          3, 'deleted 4 items' );
  is( $rsp->{total},                     4, 'delete a total of 3 items' );
  is( $rsp->{delete_markers_deleted},    1, 'deleted no delete markers' );
  is( $rsp->{multipart_uploads_aborted}, 0, 'aborted no multipart uploads' );

};

done_testing;

########################################################################
sub END {
########################################################################
  return if !$s3;

  return $s3->delete_bucket( { bucket => $bucket_name } );
}

1;
