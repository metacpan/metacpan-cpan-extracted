#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Amazon::Signature4::Lite;

########################################################################
# Helpers
########################################################################

# Fixed credentials from the AWS SigV4 test suite
my $TEST_ACCESS_KEY = 'AKIDEXAMPLE';
my $TEST_SECRET_KEY = 'wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY';
my $TEST_REGION     = 'us-east-1';
my $TEST_SERVICE    = 'service';

# 2015-08-30 12:36:00 UTC = 1440937360
my $TEST_TIME = 1440938160;

sub new_signer {
  my (%args) = @_;
  return Amazon::Signature4::Lite->new(
    access_key => $TEST_ACCESS_KEY,
    secret_key => $TEST_SECRET_KEY,
    region     => $TEST_REGION,
    service    => $TEST_SERVICE,
    %args,
  );
}

########################################################################
# constructor
########################################################################

subtest 'constructor' => sub {
  # required args
  eval { Amazon::Signature4::Lite->new( secret_key => 'x', region => 'us-east-1' ) };
  like $@, qr/access_key is required/, 'croaks without access_key';

  eval { Amazon::Signature4::Lite->new( access_key => 'x', region => 'us-east-1' ) };
  like $@, qr/secret_key is required/, 'croaks without secret_key';

  eval { Amazon::Signature4::Lite->new( access_key => 'x', secret_key => 'y' ) };
  like $@, qr/region is required/, 'croaks without region';

  # defaults
  my $s = new_signer();
  is $s->{service}, 'service', 'service set from arg';

  my $s2 = Amazon::Signature4::Lite->new(
    access_key => 'k',
    secret_key => 's',
    region     => 'us-east-1',
  );
  is $s2->{service}, 's3', 'service defaults to s3';

  # session token optional
  my $s3 = new_signer( session_token => 'TOKEN' );
  is $s3->{session_token}, 'TOKEN', 'session_token stored';
};

########################################################################
# AWS SigV4 test suite - get-vanilla
# https://docs.aws.amazon.com/general/latest/gr/sigv4-test-suite.html
########################################################################

subtest 'AWS test suite - get-vanilla' => sub {
  my $signer = new_signer();

  my $signed = $signer->sign(
    method  => 'GET',
    url     => 'https://example.amazonaws.com/',
    headers => {},
    payload => q{},
    time    => $TEST_TIME,
  );

  # Authorization header must be present and well-formed
  ok defined $signed->{Authorization}, 'Authorization header present';
  like $signed->{Authorization}, qr/^AWS4-HMAC-SHA256 /,                               'correct algorithm';
  like $signed->{Authorization}, qr/Credential=AKIDEXAMPLE\//,                         'access key in credential';
  like $signed->{Authorization}, qr{20150830/$TEST_REGION/$TEST_SERVICE/aws4_request}, 'scope correct';
  like $signed->{Authorization}, qr/SignedHeaders=/,                                   'SignedHeaders present';
  like $signed->{Authorization}, qr/Signature=[0-9a-f]{64}/,                           'Signature is 64 hex chars';

  # required headers
  like $signed->{'x-amz-date'}, qr/^\d{8}T\d{6}Z$/, 'x-amz-date format correct';
  is $signed->{'x-amz-date'}, '20150830T123600Z',      'x-amz-date value correct';
  is $signed->{'host'},       'example.amazonaws.com', 'host extracted from URL';
  ok defined $signed->{'x-amz-content-sha256'}, 'x-amz-content-sha256 present';

  # sha256 of empty string
  is $signed->{'x-amz-content-sha256'},
    'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
    'empty payload hash correct';

  # no session token when not provided
  ok !defined $signed->{'x-amz-security-token'}, 'no security token header without session_token';
};

########################################################################
# session token
########################################################################

subtest 'session token' => sub {
  my $signer = new_signer( session_token => 'AQoXnyc4lcK4w' );

  my $signed = $signer->sign(
    method => 'GET',
    url    => 'https://s3.amazonaws.com/bucket/key',
    time   => $TEST_TIME,
  );

  is $signed->{'x-amz-security-token'}, 'AQoXnyc4lcK4w', 'security token header set';
  like $signed->{Authorization}, qr/x-amz-security-token/, 'security token in SignedHeaders';
};

########################################################################
# payload hashing
########################################################################

subtest 'payload hashing' => sub {
  my $signer = new_signer();

  # scalar payload
  my $signed = $signer->sign(
    method  => 'PUT',
    url     => 'https://s3.amazonaws.com/bucket/key',
    payload => 'hello world',
    time    => $TEST_TIME,
  );
  is $signed->{'x-amz-content-sha256'},
    'b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9',
    'payload hash for "hello world"';

  # scalar ref payload
  my $data    = 'hello world';
  my $signed2 = $signer->sign(
    method  => 'PUT',
    url     => 'https://s3.amazonaws.com/bucket/key',
    payload => \$data,
    time    => $TEST_TIME,
  );
  is $signed2->{'x-amz-content-sha256'}, $signed->{'x-amz-content-sha256'}, 'scalar ref produces same hash as scalar';
};

########################################################################
# _encode_path
########################################################################

subtest '_encode_path' => sub {
  is Amazon::Signature4::Lite::_encode_path('/'), '/', 'root path unchanged';

  is Amazon::Signature4::Lite::_encode_path('/bucket/key'), '/bucket/key', 'simple path unchanged';

  is Amazon::Signature4::Lite::_encode_path('/bucket/my key.txt'), '/bucket/my%20key.txt', 'space encoded';

  is Amazon::Signature4::Lite::_encode_path('/bucket/my+key.txt'), '/bucket/my%2Bkey.txt', 'plus encoded';

  is Amazon::Signature4::Lite::_encode_path('/bucket/path/to/key/'), '/bucket/path/to/key/', 'trailing slash preserved';

  is Amazon::Signature4::Lite::_encode_path('/bucket/k[1].txt'), '/bucket/k%5B1%5D.txt', 'brackets encoded';

  # S3 uses single path encoding — % signs in existing encoded sequences
  # are encoded to %25, resulting in apparent double-encoding of the sequence
  is Amazon::Signature4::Lite::_encode_path('/bucket/key%2Fwith%2Fslashes'),
    '/bucket/key%252Fwith%252Fslashes', 'existing encoding double-encoded';

};

########################################################################
# canonical query string
########################################################################

subtest 'canonical query string' => sub {
  my $signer = new_signer();

  # query params must be sorted
  my $signed = $signer->sign(
    method => 'GET',
    url    => 'https://s3.amazonaws.com/bucket?prefix=foo&list-type=2&max-keys=10',
    time   => $TEST_TIME,
  );

  ok defined $signed->{Authorization}, 'signs URL with query string';

  # verify sorted order appears in signed headers
  # (we check that the signing didn't die and produced a signature)
  like $signed->{Authorization}, qr/Signature=[0-9a-f]{64}/, 'signature produced with query params';
};

########################################################################
# parse_service_url
########################################################################

subtest 'parse_service_url' => sub {
  # class method call
  my @r = Amazon::Signature4::Lite->parse_service_url(
    host           => 's3.amazonaws.com',
    default_region => 'us-east-1',
  );
  is $r[1], 's3',        's3 global endpoint — service';
  is $r[2], 'us-east-1', 's3 global endpoint — falls back to default region';

  # regional S3
  @r = Amazon::Signature4::Lite->parse_service_url(
    host           => 's3.us-east-2.amazonaws.com',
    default_region => 'us-east-1',
  );
  is $r[1], 's3',        'regional S3 — service';
  is $r[2], 'us-east-2', 'regional S3 — region extracted';

  # non-S3 service
  @r = Amazon::Signature4::Lite->parse_service_url(
    host           => 'ec2.us-west-2.amazonaws.com',
    default_region => 'us-east-1',
  );
  is $r[1], 'ec2',       'EC2 endpoint — service';
  is $r[2], 'us-west-2', 'EC2 endpoint — region extracted';

  # explicit service/region override
  @r = Amazon::Signature4::Lite->parse_service_url(
    host    => 's3.amazonaws.com',
    service => 'execute-api',
    region  => 'ap-southeast-1',
  );
  is $r[1], 'execute-api',    'explicit service not overridden';
  is $r[2], 'ap-southeast-1', 'explicit region not overridden';

  # LocalStack — no match, falls back to defaults
  @r = Amazon::Signature4::Lite->parse_service_url(
    host           => 'localhost:4566',
    default_region => 'us-east-1',
  );
  is $r[2], 'us-east-1', 'LocalStack falls back to default region';

  # instance method call also works
  my $signer = new_signer();
  @r = $signer->parse_service_url(
    host           => 's3.eu-west-1.amazonaws.com',
    default_region => 'us-east-1',
  );
  is $r[1], 's3',        'instance method call — service';
  is $r[2], 'eu-west-1', 'instance method call — region';
};

########################################################################
# determinism
########################################################################

subtest 'determinism' => sub {
  my $signer = new_signer();
  my %args   = (
    method  => 'GET',
    url     => 'https://s3.amazonaws.com/bucket/key',
    payload => q{},
    time    => $TEST_TIME,
  );

  my $sig1 = $signer->sign(%args)->{Authorization};
  my $sig2 = $signer->sign(%args)->{Authorization};
  is $sig1, $sig2, 'same inputs produce same signature';
};

########################################################################
# header passthrough
########################################################################

subtest 'extra headers included in signing' => sub {
  my $signer = new_signer();

  my $signed = $signer->sign(
    method  => 'PUT',
    url     => 'https://s3.amazonaws.com/bucket/key',
    headers => {
      'Content-Type' => 'application/gzip',
      'x-amz-acl'    => 'private',
    },
    time => $TEST_TIME,
  );

  is $signed->{'Content-Type'}, 'application/gzip', 'Content-Type passed through';
  is $signed->{'x-amz-acl'},    'private',          'x-amz-acl passed through';
  like $signed->{Authorization}, qr/content-type/, 'Content-Type in SignedHeaders';
  like $signed->{Authorization}, qr/x-amz-acl/,    'x-amz-acl in SignedHeaders';
};

########################################################################
# error handling
########################################################################

subtest 'error handling' => sub {
  my $signer = new_signer();

  eval { $signer->sign( method => 'GET' ) };
  like $@, qr/url is required/, 'croaks without url';
};

subtest 'AWS test suite - get-vanilla exact signature' => sub {
  my $signer = new_signer();

  my $signed = $signer->sign(
    method  => 'GET',
    url     => 'https://example.amazonaws.com/',
    headers => {},
    payload => q{},
    time    => $TEST_TIME,
  );

  is $signed->{Authorization},
    'AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20150830/us-east-1/service/aws4_request, SignedHeaders=host;x-amz-content-sha256;x-amz-date, Signature=726c5c4879a6b4ccbbd3b24edbd6b8826d34f87450fbbf4e85546fc7ba9c1642',
    'exact Authorization header matches AWS test suite get-vanilla';
};

done_testing;
