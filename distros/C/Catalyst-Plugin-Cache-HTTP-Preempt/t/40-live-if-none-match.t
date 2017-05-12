#!/usr/bin/env perl

# Test the If-Modified-Since header

use strict;
use warnings;

use DateTime;
use DateTime::Format::HTTP;
use HTTP::Request::Common;
use HTTP::Status qw( :constants );
use URI;

use Test::More;

# setup library path
use FindBin qw($Bin);
use lib "$Bin/lib";

# make sure testapp works
use ok 'TestApp';

# a live test against TestApp, the test application
use Test::WWW::Mechanize::Catalyst 'TestApp';
my $m = Test::WWW::Mechanize::Catalyst->new;

my $time  = DateTime->now->subtract( minutes => 123 );
my $htime = DateTime::Format::HTTP->format_datetime( $time );

my $uri = URI->new('http://localhost/');
$uri->query_form( 'Last-Modified' => $htime, 'strong' => 0 );

my $res;

$res = $m->request( GET $uri );
ok($res->is_success, "HTTP_OK");
is($res->header('Last-Modified'), $htime,   "Last-Modified");
ok(defined $res->header('Expires'), "Expires");
my $etag = $res->header('ETag');
note($etag);
ok(defined $etag, "ETag") or BAIL_OUT "missing ETag";
like($etag, qr/^W\//, "weak ETag");

$m->content_like(qr/Content[ ]Ok/, 'expected text');

$res = $m->request( GET $uri, 'If-None-Match' => '"*"' );
is($res->code, HTTP_NOT_MODIFIED, "HTTP_NOT_MODIFIED");
is($res->header('Last-Modified'), $htime,   "Last-Modified");
ok(!defined $res->header('Expires'), "Expires");
is($res->header('ETag'), $etag, "ETag");
$m->content_is("", "no content");

$res = $m->request( GET $uri, 'If-None-Match' => $etag );
is($res->code, HTTP_NOT_MODIFIED, "HTTP_NOT_MODIFIED");
is($res->header('Last-Modified'), $htime,   "Last-Modified");
ok(!defined $res->header('Expires'), "Expires");
is($res->header('ETag'), $etag, "ETag");
$m->content_is("", "no content");

$res = $m->request( GET $uri, 'If-None-Match' => '"xyzzy", "xyz"' );
is($res->code, HTTP_OK, "HTTP_OK");
is($res->header('Last-Modified'), $htime,   "Last-Modified");
ok(defined $res->header('Expires'), "Expires");
is($res->header('ETag'), $etag, "ETag");
$m->content_like(qr/Content[ ]Ok/, 'expected text');

# This should not match for weak comparison for methods other than GET or HEAD

$res = $m->request( PUT $uri, 'If-None-Match' => '*' );
is($res->code, HTTP_OK, "HTTP_OK");
is($res->header('Last-Modified'), $htime,   "Last-Modified");
ok(defined $res->header('Expires'), "Expires");
is($res->header('ETag'), $etag, "ETag");
$m->content_like(qr/Content[ ]Ok/, 'expected text');

$res = $m->request( PUT $uri, 'If-None-Match' => $etag );
is($res->code, HTTP_OK, "HTTP_OK");
is($res->header('Last-Modified'), $htime,   "Last-Modified");
ok(defined $res->header('Expires'), "Expires");
is($res->header('ETag'), $etag, "ETag");
$m->content_like(qr/Content[ ]Ok/, 'expected text');

$uri = URI->new('http://localhost/');
$uri->query_form( 'Last-Modified' => $htime, 'strong' => 1 );

$etag = substr($etag, 2); # string "W/" prefix

$res = $m->request( PUT $uri, 'If-None-Match' => '"*"' );
is($res->code, HTTP_PRECONDITION_FAILED, "HTTP_PRECONDITION_FAILED");
is($res->header('Last-Modified'), $htime,   "Last-Modified");
ok(!defined $res->header('Expires'), "Expires");
is($res->header('ETag'), $etag, "ETag");
$m->content_is("", "no content");

$res = $m->request( PUT $uri, 'If-None-Match' => $etag );
is($res->code, HTTP_PRECONDITION_FAILED, "HTTP_PRECONDITION_FAILED");
is($res->header('Last-Modified'), $htime,   "Last-Modified");
ok(!defined $res->header('Expires'), "Expires");
is($res->header('ETag'), $etag, "ETag");
$m->content_is("", "no content");

done_testing;
