use strict;
use warnings;

use Test::Most;
use Digest::SHA qw(hmac_sha256_hex);
use MIME::Base64 qw(decode_base64url encode_base64url);
use Catalyst::Plugin::CSRFToken;

for my $expected (
  encode_base64url('x' x 32), # Current non-HMAC token: 43 bytes of text
  'a' x 64,                   # Current HMAC-SHA256 hex token
) {
  subtest 'masked representation round trips for length '.length($expected) => sub {
    my $first = Catalyst::Plugin::CSRFToken->_mask_csrf_token($expected);
    my $second = Catalyst::Plugin::CSRFToken->_mask_csrf_token($expected);

    like $first, qr/\A[A-Za-z0-9_-]+\z/, 'first payload is canonical base64url text';
    like $second, qr/\A[A-Za-z0-9_-]+\z/, 'second payload is canonical base64url text';
    isnt $first, $second, 'fresh mask changes every wire representation';

    my $decoded = decode_base64url($first);
    is length($decoded), length($expected) * 2, 'payload contains mask and masked token';
    is(Catalyst::Plugin::CSRFToken->_unmask_csrf_token($first, length($expected)),
      $expected,
      'payload unmasks to the expected token');
  };
}

subtest 'malformed payloads are rejected' => sub {
  my $expected = 'a' x 64;
  my $valid = Catalyst::Plugin::CSRFToken->_mask_csrf_token($expected);

  ok !defined Catalyst::Plugin::CSRFToken->_unmask_csrf_token(undef, length($expected)),
    'undefined payload is rejected';
  ok !defined Catalyst::Plugin::CSRFToken->_unmask_csrf_token('', length($expected)),
    'empty payload is rejected';
  ok !defined Catalyst::Plugin::CSRFToken->_unmask_csrf_token('not*base64url', length($expected)),
    'non-base64url character is rejected';
  ok !defined Catalyst::Plugin::CSRFToken->_unmask_csrf_token($valid, 0),
    'zero expected length is rejected';
  ok !defined Catalyst::Plugin::CSRFToken->_unmask_csrf_token(
    encode_base64url('x' x ((length($expected) * 2) - 1)),
    length($expected),
  ), 'short decoded payload is rejected';
  ok !defined Catalyst::Plugin::CSRFToken->_unmask_csrf_token(
    encode_base64url('x' x ((length($expected) * 2) + 1)),
    length($expected),
  ), 'long decoded payload is rejected';

  my $noncanonical = $valid.'=';
  ok !defined Catalyst::Plugin::CSRFToken->_unmask_csrf_token(
    $noncanonical,
    length($expected),
  ), 'padded base64 is rejected';
};

{
  package Local::CSRFContext;

  sub new {
    my ($class, $secret) = @_;
    return bless { secret => $secret }, $class;
  }

  sub csrf_default_secret {
    return shift->{secret};
  }
}

subtest 'expected token honors optional default_secret' => sub {
  my $entry = { value => 'stored-session-token' };
  my $without_secret = Local::CSRFContext->new(undef);
  my $with_secret = Local::CSRFContext->new('configured-secret');

  is(Catalyst::Plugin::CSRFToken::_csrf_expected_token($without_secret, $entry),
    $entry->{value},
    'stored token is used directly when default_secret is absent');
  is(Catalyst::Plugin::CSRFToken::_csrf_expected_token($with_secret, $entry),
    hmac_sha256_hex($entry->{value}, 'configured-secret'),
    'configured default_secret produces the expected HMAC');
};

done_testing;
