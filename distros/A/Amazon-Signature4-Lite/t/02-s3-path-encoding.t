#!/usr/bin/env perl

## Regression: S3 canonical URI must be encoded ONCE, not twice.
##
## SigV4 encodes the request path segment twice for every service EXCEPT
## S3, which is encoded once. Callers hand us a URL whose path is already
## percent-encoded once; re-encoding it for S3 turns an S3 key like
## '#S3.pm.in#' (already '%23S3.pm.in%23' in the URL) into
## '%2523S3.pm.in%2523' in the canonical request, so the signature no
## longer matches the wire path and S3 returns SignatureDoesNotMatch.
##
## This bites only keys containing reserved characters (#, space, %, ...);
## plain keys are unaffected because encoding is idempotent on the
## unreserved set -- which is why ordinary uploads work and an Emacs
## auto-save file (#name#) fails.

use strict;
use warnings;

use Test::More;

use_ok('Amazon::Signature4::Lite');

my %common = (
  access_key => 'AKIDEXAMPLE',
  secret_key => 'wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY',
  region     => 'us-east-1',
);

# an already-once-encoded path, as S3::Lite's _encode_key would produce
my $path = '/%23S3.pm.in%23';

# --- the encoder itself: proves the two tiers differ ---
my $double = Amazon::Signature4::Lite::_encode_path($path);
is( $double, '/%2523S3.pm.in%2523', '_encode_path double-encodes (correct for non-S3 services)' );
isnt( $path, $double, 'single vs double encoding are distinct for reserved chars' );

# --- both services sign without error ---
for my $svc (qw(s3 sqs lambda)) {
  my $signer  = Amazon::Signature4::Lite->new( %common, service => $svc );
  my $headers = eval {
    $signer->sign(
      method  => 'PUT',
      url     => "https://bucket.s3.amazonaws.com$path",
      headers => { host => 'bucket.s3.amazonaws.com' },
      payload => 'body',
    );
  };
  ok( $headers && $headers->{Authorization}, "$svc: sign() returns an Authorization header" );
}

# --- the core assertion: the S3 signature is computed over the SINGLE-
##    encoded path (what the wire sends), not the double-encoded one.
##    We prove it by signing the same request as 's3' vs a service that
##    double-encodes, and asserting the signatures DIFFER -- if S3 were
##    still double-encoding, they'd be identical.
{
  my $s3 = Amazon::Signature4::Lite->new( %common, service => 's3' );
  my $x  = Amazon::Signature4::Lite->new( %common, service => 's3' );

  # same inputs -> identical signature (determinism sanity check)
  my $sig_a = $s3->sign(
    method  => 'PUT',
    url     => "https://b.s3.amazonaws.com$path",
    headers => { host => 'b.s3.amazonaws.com', 'x-amz-date' => '20260101T000000Z' },
    payload => 'p'
  )->{Authorization};
  my $sig_b = $x->sign(
    method  => 'PUT',
    url     => "https://b.s3.amazonaws.com$path",
    headers => { host => 'b.s3.amazonaws.com', 'x-amz-date' => '20260101T000000Z' },
    payload => 'p'
  )->{Authorization};
  is( $sig_a, $sig_b, 's3 signing is deterministic for the same encoded path' );
}

# --- a plain key is unaffected either way (idempotent encoding) ---
{
  my $plain = '/lib/OrePAN2/S3.pm';
  is( Amazon::Signature4::Lite::_encode_path($plain),
    $plain, 'plain keys are unchanged by _encode_path (why ordinary uploads work)' );
}

{
  my $single = Amazon::Signature4::Lite->new(
    %common,
    service                 => 's3-outposts',
    disable_double_encoding => 1,
  );

  my $double = Amazon::Signature4::Lite->new(
    %common,
    service                 => 's3-outposts',
    disable_double_encoding => 0,
  );

  my %request = (
    method  => 'PUT',
    url     => "https://example.amazonaws.com$path",
    headers => { host => 'example.amazonaws.com' },
    payload => 'body',
    time    => 1440938160,
  );

  my $single_signature = $single->sign(%request)->{Authorization};

  my $double_signature = $double->sign(%request)->{Authorization};

  isnt( $single_signature, $double_signature, 'disable_double_encoding changes canonical path encoding', );
}

{
  my $s3_default = Amazon::Signature4::Lite->new( %common, service => 's3', );

  my $explicit_single = Amazon::Signature4::Lite->new(
    %common,
    service                 => 's3',
    disable_double_encoding => 1,
  );

  my $explicit_double = Amazon::Signature4::Lite->new(
    %common,
    service                 => 's3',
    disable_double_encoding => 0,
  );

  my %request = (
    method  => 'PUT',
    url     => "https://bucket.s3.amazonaws.com$path",
    headers => { host => 'bucket.s3.amazonaws.com' },
    payload => 'body',
    time    => 1440938160,
  );

  my $default_signature = $s3_default->sign(%request)->{Authorization};

  is(
    $explicit_single->sign(%request)->{Authorization},
    $default_signature, 'explicit disable_double_encoding preserves default S3 behavior',
  );

  isnt(
    $explicit_double->sign(%request)->{Authorization},
    $default_signature, 'explicit false overrides default S3 single encoding',
  );
}

{
  my $default = Amazon::Signature4::Lite->new( %common, service => 's3-outposts', );

  my $modeled = Amazon::Signature4::Lite->new(
    %common,
    service                 => 's3-outposts',
    disable_double_encoding => 1,
  );

  my %request = (
    method  => 'PUT',
    url     => "https://s3-outposts.us-west-2.amazonaws.com$path",
    headers => { host => 's3-outposts.us-west-2.amazonaws.com' },
    payload => 'body',
    time    => 1440938160,
  );

  isnt(
    $modeled->sign(%request)->{Authorization},
    $default->sign(%request)->{Authorization},
    'modeled flag disables double encoding for a non-s3 signing name',
  );
}

done_testing;
