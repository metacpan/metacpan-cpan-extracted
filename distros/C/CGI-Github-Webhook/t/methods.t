#!/usr/bin/perl

use strict;
use warnings;
use 5.010;

use Test::More;
use File::Temp qw(tempfile tempdir);
use Digest::SHA qw(hmac_sha1_hex);
use File::Basename;
use File::Slurper qw(read_text);
use Test::File;
use Test::File::ShareDir
    -share => {
        -module => {
            'CGI::Github::Webhook' => dirname($0).'/../static-badges/',
        },
};

my ($fh1, $tmplog) = tempfile();
my ($fh2, $tmpout) = tempfile();
my $tmpdir = tempdir( CLEANUP => 1 );
my $secret = 'bar';
my $json = '{"fnord":"gnarz"}';
my $signature = 'sha1='.hmac_sha1_hex($json, $secret);
my $dir = dirname($0);
my $badge = "$tmpdir/badge.svg";

$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
$ENV{REQUEST_METHOD} = 'GET';

use_ok('CGI::Github::Webhook');

# No X-Hub-Signature, no payload
my $ghwh = CGI::Github::Webhook->new(
    trigger => 'echo foo',
    trigger_backgrounded => 0,
    secret => 'any',
    log => $tmplog,
    );

is($ghwh->header(),
   "Content-Type: text/plain; charset=utf-8\r\n\r\n",
   'header method returns expected Content-Type header');
ok(!$ghwh->authenticated, 'Authentication failed');

$ENV{HTTP_X_HUB_SIGNATURE} = $signature;
$ENV{QUERY_STRING} = "POSTDATA=$json";

# Successful authentication
$ghwh = CGI::Github::Webhook->new(
    trigger => 'echo foo',
    trigger_backgrounded => 0,
    secret => $secret,
    log => $tmplog,
    badge_to => $badge,
    );

is($ghwh->header(),
   "Content-Type: text/plain; charset=utf-8\r\n\r\n",
   'header method returns expected Content-Type header');
is($ghwh->payload, $json, 'Raw payload returned as expected');
is($ghwh->payload_json, $json, 'JSON payload returned as expected');
is_deeply($ghwh->payload_perl, { fnord => 'gnarz' },
          'Perl data structure payload returned as expected');
ok($ghwh->authenticated, 'Authentication successful');
ok($ghwh->authenticated,
   'Authentication still considered successful on a second retrieval');
ok($ghwh->deploy_badge("success"),
   'Badge could be deployed successfully');
file_exists_ok($badge);
file_readable_ok($badge);
file_contains_like($badge, qr/<svg.*success/s, "'success' and is an SVG file");

# Failed authentication
$ghwh = CGI::Github::Webhook->new(
    trigger => 'echo foo',
    trigger_backgrounded => 0,
    secret => 'the wrong one',
    log => $tmplog,
    badge_to => $badge,
    );

is($ghwh->header(),
   "Content-Type: text/plain; charset=utf-8\r\n\r\n",
   'header method returns expected Content-Type header');
is($ghwh->payload, $json, 'Raw payload returned as expected');
is($ghwh->payload_json, $json, 'JSON payload returned as expected');
is_deeply($ghwh->payload_perl, { fnord => 'gnarz' },
          'Perl data structure payload returned as expected');
ok(!$ghwh->authenticated, 'Authentication failed');
ok(!$ghwh->authenticated,
   'Authentication still considered failing on a second retrieval');
ok($ghwh->deploy_badge("failed"),
   'Badge could be deployed successfully');
file_exists_ok($badge);
file_readable_ok($badge);
file_contains_like($badge, qr/<svg.*failed/s, "'failed' and is an SVG file");

done_testing();
