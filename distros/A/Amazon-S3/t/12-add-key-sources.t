#!/usr/bin/env perl

use strict;
use warnings;

use lib q(t/lib);

use English qw(-no_match_vars);
use File::Temp qw(tempfile);
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
my $bucket_name = "test-add-key-sources-$PID";

eval { $s3->add_bucket( { bucket => $bucket_name, } ); };

BAIL_OUT("could not create bucket $bucket_name: $EVAL_ERROR")
  if $EVAL_ERROR;

my $bucket = $s3->bucket($bucket_name);

my $content = <<'END_OF_CONTENT';
Lorem ipsum dolor sit amet, consectetur adipiscing elit.
Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
END_OF_CONTENT

########################################################################
subtest 'data source' => sub {
########################################################################
  my $key = 'data.txt';

  my $rsp = $bucket->add_key(
    { key          => $key,
      data         => $content,
      content_type => 'text/plain',
    }
  );

  ok( $rsp, 'uploaded object from data' );

  my $object = $bucket->get_key($key);

  isa_ok( $object, 'HASH', 'get_key response' );
  is( $object->{value}, $content, 'uploaded data matches source' );
};

########################################################################
subtest 'filename source' => sub {
########################################################################
  my $key = 'filename.txt';

  my ( $fh, $filename ) = tempfile();

  $fh->binmode;

  print {$fh} $content
    or BAIL_OUT("could not write temporary test file: $OS_ERROR");

  $fh->close
    or BAIL_OUT("could not close temporary test file: $OS_ERROR");

  my $rsp = $bucket->add_key(
    { key          => $key,
      filename     => $filename,
      content_type => 'text/plain',
    }
  );

  ok( $rsp, 'uploaded object from filename' );

  my $object = $bucket->get_key($key);

  isa_ok( $object, 'HASH', 'get_key response' );
  is( $object->{value}, $content, 'uploaded filename matches source' );

  ok( -e $filename, 'caller supplied file was not removed' );
};

########################################################################
subtest 'filehandle source' => sub {
########################################################################
  my $key = 'filehandle.txt';

  my ( $fh, $filename ) = tempfile();

  $fh->binmode;

  print {$fh} $content
    or BAIL_OUT("could not write temporary test file: $OS_ERROR");

  $fh->seek( 0, 0 )
    or BAIL_OUT("could not rewind temporary test file: $OS_ERROR");

  my $rsp = $bucket->add_key(
    { key          => $key,
      fh           => $fh,
      content_type => 'text/plain',
    }
  );

  ok( $rsp, 'uploaded object from filehandle' );

  my $object = $bucket->get_key($key);

  isa_ok( $object, 'HASH', 'get_key response' );
  is( $object->{value}, $content, 'uploaded filehandle matches source' );
};

########################################################################
subtest 'callback source' => sub {
########################################################################
  my $key = 'callback.txt';

  my @chunks = (
    'Lorem ipsum ',
    'dolor sit amet, ',
    "consectetur adipiscing elit.\n",
    'Sed do eiusmod tempor incididunt ',
    "ut labore et dolore magna aliqua.\n",
  );

  my $callback = sub {
    return
      if !@chunks;

    my $chunk = shift @chunks;

    return \$chunk;
  };

  my $rsp = $bucket->add_key(
    { key          => $key,
      callback     => $callback,
      content_type => 'text/plain',
    }
  );

  ok( $rsp, 'uploaded object from callback' );

  my $object = $bucket->get_key($key);

  isa_ok( $object, 'HASH', 'get_key response' );
  is( $object->{value}, $content, 'uploaded callback chunks match source' );
};

done_testing;

########################################################################
sub END {
########################################################################
  return if !$s3;

  eval {
    $s3->empty_bucket($bucket_name);
    $s3->delete_bucket( { bucket => $bucket_name } );
  };

  return;
}

1;
