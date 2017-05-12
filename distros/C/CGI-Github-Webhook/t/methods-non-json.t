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
my $non_json = 'fnord';
my $signature_non_json = 'sha1='.hmac_sha1_hex($non_json, $secret);
my $dir = dirname($0);
my $badge = "$tmpdir/badge.svg";

$ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
$ENV{REQUEST_METHOD} = 'GET';

use_ok('CGI::Github::Webhook');

# Non-JSON payload
$ENV{HTTP_X_HUB_SIGNATURE} = $signature_non_json;
$ENV{QUERY_STRING} = "POSTDATA=$non_json";

my $ghwh = CGI::Github::Webhook->new(
    trigger => 'echo foo',
    trigger_backgrounded => 0,
    secret => $secret,
    log => $tmplog,
    badge_to => $badge,
    );

is($ghwh->header(),
   "Content-Type: text/plain; charset=utf-8\r\n\r\n",
   'header method returns expected Content-Type header');
is($ghwh->payload, $non_json, 'Raw payload returned as expected');
like($ghwh->payload_json, qr/^\{"error":"/,
     'JSON payload returned error as expected');
ok($ghwh->authenticated, 'Authentication successful');
ok($ghwh->authenticated,
   'Authentication still considered successful on a second retrieval');
ok($ghwh->deploy_badge("success"),
   'Badge could be deployed successfully');
file_exists_ok($badge);
file_readable_ok($badge);
TODO: {
    local $TODO = 'Should really fail in this case?';
    file_contains_like($badge, qr/<svg.*failed/s, "'failed' and is an SVG file");
}

done_testing();
