#!/usr/bin/env perl -w

use strict;
use warnings;

use English qw(-no_match_vars);
use List::Util qw(pairs);
use Test::More;

use Amazon::S3::BucketV2;

{

  package Local::S3Account;

  sub new {
    my ($class) = @_;

    return bless { request => undef }, $class;
  }

  sub send_request {
    my ( $self, $request ) = @_;

    $self->{request} = $request;

    return $request;
  }

  sub request {
    my ($self) = @_;

    return $self->{request};
  }
}

my $account = Local::S3Account->new();

my $bucket = bless {
  account => $account,
  bucket  => 'test-bucket',
  region  => 'us-east-1',
  },
  'Amazon::S3::BucketV2';

########################################################################
sub request_for {
########################################################################
  my ( $method, @args ) = @_;

  $bucket->$method(@args);

  return $account->request;
}

########################################################################
subtest 'generated methods exist' => sub {
########################################################################
  my @method_definitions = (
    @Amazon::S3::BucketV2::GET_OBJECT_METHODS,    @Amazon::S3::BucketV2::GET_BUCKET_METHODS,
    @Amazon::S3::BucketV2::PUT_BUCKET_METHODS,    @Amazon::S3::BucketV2::PUT_OBJECT_METHODS,
    @Amazon::S3::BucketV2::DELETE_OBJECT_METHODS, @Amazon::S3::BucketV2::DELETE_BUCKET_METHODS,
  );

  my @methods = qw(head_object head_bucket);

  for my $pair ( pairs @method_definitions ) {
    push @methods, $pair->[0];
  }

  for my $method (@methods) {
    my $camel_case = Amazon::S3::BucketV2::to_camel_case($method);

    ok( $bucket->can($camel_case), "$camel_case is available" );
  }
};

########################################################################
subtest 'bucket GET operation' => sub {
########################################################################
  my $request = request_for('GetBucketVersioning');

  is( $request->{method}, 'GET',                     'uses GET' );
  is( $request->{path},   'test-bucket/?versioning', 'constructs bucket API path' );
  is( $request->{region}, 'us-east-1',               'uses bucket region' );
};

########################################################################
subtest 'object DELETE operation' => sub {
########################################################################
  my $request = request_for(
    'DeleteObject',
    key       => 'foo',
    uri_param => { versionId       => 'version-1' },
    headers   => { 'x-test-header' => 'test-value' },
  );

  is( $request->{method}, 'DELETE',                              'uses DELETE' );
  is( $request->{path},   'test-bucket/foo?versionId=version-1', 'constructs object path with URI parameters' );
  is( $request->{headers}{'x-test-header'}, 'test-value',        'passes headers through' );
};

########################################################################
subtest 'request body serialization' => sub {
########################################################################
  my $request = request_for( 'DeleteObjects', body => { Delete => { Object => [ { Key => 'one' }, { Key => 'two' }, ], }, }, );

  is( $request->{method}, 'POST',                'DeleteObjects uses POST' );
  is( $request->{path},   'test-bucket/?delete', 'uses delete API path' );
  like( $request->{data}, qr{<Delete\b}xsm,      'serializes request body' );
  like( $request->{data}, qr{<Key>one</Key>}xsm, 'serializes first key' );
  ok( $request->{headers}{'Content-MD5'}, 'adds Content-MD5' );
};

########################################################################
subtest 'method overrides do not leak to later generated methods' => sub {
########################################################################
  my $request = request_for( 'RestoreObject', key => 'foo' );

  is( $request->{method}, 'POST', 'RestoreObject uses POST' );

  $request = request_for(
    'UploadPart',
    key       => 'foo',
    uri_param => {
      partNumber => 1,
      uploadId   => 'upload-1',
    },
  );

  is( $request->{method}, 'PUT', 'UploadPart uses PUT' );

  $request = request_for( 'DeleteObjects', body => { Delete => { Object => [ { Key => 'one' }, ], }, }, );

  is( $request->{method}, 'POST', 'DeleteObjects uses POST' );

  $request = request_for( 'DeleteObjectTagging', key => 'foo' );

  is( $request->{method}, 'DELETE', 'DeleteObjectTagging uses DELETE' );
};

done_testing;
