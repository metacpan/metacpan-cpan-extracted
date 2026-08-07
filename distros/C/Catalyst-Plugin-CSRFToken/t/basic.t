use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use Catalyst::Test 'MyApp';
use Test::Most;
use HTTP::Request::Common;
use Digest::SHA qw(hmac_sha256_hex);

# A rejected token makes Catalyst log the thrown exception to STDERR. Capture
# that output so the suite stays quiet and so the rejection is asserted rather
# than merely printed.
sub request_rejecting_token {
  my @args = @_;
  my $logged = '';
  my $res;
  {
    open my $capture, '>', \$logged or die "cannot open capture handle: $!";
    local *STDERR = $capture;
    $res = request(@args);
  }
  return ($res, $logged);
}

{
  ok my $first_res = request '/get';
  ok my $first_token = $first_res->content;
  ok my $second_res = request '/get';
  ok my $second_token = $second_res->content;

  like $first_token, qr/\Adefault:v2:[A-Za-z0-9_-]+\z/, 'first token uses v2 wire format';
  like $second_token, qr/\Adefault:v2:[A-Za-z0-9_-]+\z/, 'second token uses v2 wire format';
  isnt $first_token, $second_token, 'single-use action receives fresh masked representations';

  {
    ok my $res = request POST '/test', [csrf_token2 => $first_token];
    is $res->content, 'ok', 'first masked representation validates';
  }
  {
    my ($res, $logged) = request_rejecting_token(POST '/test', [csrf_token2 => $second_token]);
    ok $res, 'request completed';
    is $res->content, 'Forbidden: Invalid CSRF token.',
      'all representations fail after the single-use session token is consumed';
    like $logged, qr/csrf_token failed validation/,
      'rejection is logged';
  }
}

{
  ok my $first_res = request '/get_reusable';
  ok my $first_token = $first_res->content;
  ok my $second_res = request '/get_reusable';
  ok my $second_token = $second_res->content;

  like $first_token, qr/\Areusable:v2:[A-Za-z0-9_-]+\z/, 'reusable token uses v2 wire format';
  like $second_token, qr/\Areusable:v2:[A-Za-z0-9_-]+\z/, 'second reusable token uses v2 wire format';
  isnt $first_token, $second_token, 'reusable session token is masked differently every time';

  {
    ok my $res = request POST '/reusable', [csrf_token2 => $first_token];
    is $res->content, 'ok', 'first masked representation validates';
  }
  {
    ok my $res = request POST '/reusable', [csrf_token2 => $second_token];
    is $res->content, 'ok', 'second masked representation also validates';
  }
  {
    my $req = POST '/reusable';
    $req->header('X-CSRF-Token' => $second_token);
    ok my $res = request $req;
    is $res->content, 'ok', 'masked representation validates from request header';
  }
  {
    my ($prefix, $payload) = $first_token =~ /\A(.*:v2:)([A-Za-z0-9_-]+)\z/;
    my $replacement = substr($payload, 10, 1) eq 'A' ? 'B' : 'A';
    substr($payload, 10, 1, $replacement);
    my $tampered = $prefix.$payload;

    my ($res, $logged) = request_rejecting_token(POST '/reusable', [csrf_token2 => $tampered]);
    ok $res, 'request completed';
    is $res->content, 'Forbidden: Invalid CSRF token.', 'tampered masked token is rejected';
    like $logged, qr/csrf_token failed validation/, 'rejection is logged';
  }
  {
    my $entry = MyApp->session->{'_csrf_token2_reusable'};
    my $legacy = 'reusable:'.hmac_sha256_hex($entry->{value}, 'begin');

    my ($res, $logged) = request_rejecting_token(POST '/reusable', [csrf_token2 => $legacy]);
    ok $res, 'request completed';
    is $res->content, 'Forbidden: Invalid CSRF token.', 'unmasked 1.001 token is rejected';
    like $logged, qr/csrf_token failed validation/, 'rejection is logged';
  }
  {
    my ($res, $logged) = request_rejecting_token(POST '/reusable', [csrf_token2 => ['one', 'two']]);
    ok $res, 'request completed';
    is $res->content, 'Forbidden: Invalid CSRF token.', 'non-scalar token is rejected';
    like $logged, qr/csrf_token failed validation/, 'rejection is logged';
  }
}

{
  ok my $res = request POST '/skip';
  is $res->content, 'ok';
}

{
  ok my $res = request '/config_test';
  my $VAR1;
  ok eval $res->content;

  is_deeply $VAR1, {
    'token_session_key' => '_csrf_token2',
    'max_age' => 8888,
    'default_secret' => 'begin',
    'token_param_key' => 'csrf_token2',
  };
}

done_testing;
