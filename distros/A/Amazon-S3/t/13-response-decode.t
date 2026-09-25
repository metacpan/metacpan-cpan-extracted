#!/usr/bin/env perl

use strict;
use warnings;

use Amazon::S3;
use English qw(-no_match_vars);
use HTTP::Response;
use JSON::PP;
use Test::More;

my $s3 = Amazon::S3->new(
  { aws_access_key_id     => 'test-access-key',
    aws_secret_access_key => 'test-secret-key',
  }
);

########################################################################
subtest 'xml response' => sub {
########################################################################
  my $response = HTTP::Response->new(
    200, 'OK',
    [ 'Content-Type' => 'application/xml' ],
    '<?xml version="1.0"?><PolicyStatus><IsPublic>false</IsPublic></PolicyStatus>',
  );

  my $content = $s3->_decode_response($response);

  is_deeply( $content, { IsPublic => 'false' }, 'XML response decoded', );

  return;
};

########################################################################
subtest 'json response' => sub {
########################################################################
  my $response
    = HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'application/json' ], '{"Version":"2012-10-17","Enabled":true}', );

  my $content = $s3->_decode_response($response);

  is_deeply(
    $content,
    { Version => '2012-10-17',
      Enabled => JSON::PP::true,
    },
    'JSON response decoded',
  );

  return;
};

########################################################################
subtest 'json mislabeled as xml' => sub {
########################################################################
  my $response = HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'application/xml' ], '{"Version":"2012-10-17"}', );

  my @warnings;

  local $SIG{__WARN__} = sub {
    push @warnings, @_;
    return;
  };

  my $content = $s3->_decode_response($response);

  is_deeply( $content, { Version => '2012-10-17' }, 'mislabeled JSON recovered', );

  is_deeply( \@warnings, [], 'mislabeled JSON does not reach XML parser', );

  return;
};

########################################################################
subtest 'json with unknown content type' => sub {
########################################################################
  my $response = HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'text/plain' ], '{"Status":"ok"}', );

  my $content = $s3->_decode_response($response);

  is_deeply( $content, { Status => 'ok' }, 'JSON fallback decodes response', );

  return;
};

########################################################################
subtest 'raw response fallback' => sub {
########################################################################
  my $response = HTTP::Response->new( 200, 'OK', [ 'Content-Type' => 'text/plain' ], 'plain response', );

  is( $s3->_decode_response($response), 'plain response', 'unknown response returned unchanged', );

  return;
};

########################################################################
subtest 'empty successful response' => sub {
########################################################################
  my $response = HTTP::Response->new( 204, 'No Content', );

  is( $s3->_decode_response($response), undef, 'empty successful response returns undef', );

  return;
};

########################################################################
subtest 'error response' => sub {
########################################################################
  my $response = HTTP::Response->new(
    404, 'Not Found',
    [ 'Content-Type' => 'application/xml' ],
    '<?xml version="1.0"?><Error><Code>NoSuchBucket</Code><Message>The specified bucket does not exist</Message></Error>',
  );

  my $content = $s3->_decode_response($response);

  is( $content, undef, 'error response returns undef', );

  is( $s3->err, 'NoSuchBucket', 'error code retained', );

  is( $s3->errstr, 'The specified bucket does not exist', 'error message retained', );

  return;
};

done_testing();

1;
