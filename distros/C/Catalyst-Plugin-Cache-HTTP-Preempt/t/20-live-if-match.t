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
$uri->query_form( 'Last-Modified' => $htime, 'strong' => 1 );

my $res;

$res = $m->request( GET $uri );
ok($res->is_success, "HTTP_OK");
is($res->header('Last-Modified'), $htime,   "Last-Modified");
ok(defined $res->header('Expires'), "Expires");
my $etag = $res->header('ETag');
note($etag);
ok(defined $etag, "ETag") or BAIL_OUT "missing ETag";
unlike($etag, qr/^W\//, "strong ETag");

$m->content_like(qr/Content[ ]Ok/, 'expected text');

$res = $m->request( GET $uri, 'If-Match' => '*' );
ok($res->is_success, "HTTP_OK");
is($res->header('Last-Modified'), $htime,   "Last-Modified");
ok(defined $res->header('Expires'), "Expires");
is($res->header('ETag'), $etag, "ETag");
$m->content_like(qr/Content[ ]Ok/, 'expected text');

$res = $m->request( GET $uri, 'If-Match' => $etag );
ok($res->is_success, "HTTP_OK");
is($res->header('Last-Modified'), $htime,   "Last-Modified");
ok(defined $res->header('Expires'), "Expires");
is($res->header('ETag'), $etag, "ETag");
$m->content_like(qr/Content[ ]Ok/, 'expected text');

$res = $m->request( GET $uri, 'If-Match' => join(", ", '"xyz"', $etag) );
ok($res->is_success, "HTTP_OK");
is($res->header('Last-Modified'), $htime,   "Last-Modified");
ok(defined $res->header('Expires'), "Expires");
is($res->header('ETag'), $etag, "ETag");
$m->content_like(qr/Content[ ]Ok/, 'expected text');

$res = $m->request( GET $uri, 'If-Match' => '"xyzzy"' );
is($res->code, HTTP_PRECONDITION_FAILED, "HTTP_PRECONDITION_FAILED");
is($res->header('Last-Modified'), $htime,   "Last-Modified");
ok(!defined $res->header('Expires'), "Expires");
is($res->header('ETag'), $etag, "ETag");
$m->content_is("", 'no content');

$uri = URI->new('http://localhost/');
$uri->query_form( 'Last-Modified' => $htime, 'strong' => 0 );

$res = $m->request( GET $uri, 'If-Match' => '*' );
is($res->code, HTTP_PRECONDITION_FAILED, "HTTP_PRECONDITION_FAILED");
is($res->header('Last-Modified'), $htime,   "Last-Modified");
ok(!defined $res->header('Expires'), "Expires");
is($res->header('ETag'), "W/${etag}", "ETag");
$m->content_is("", 'no content');

$res = $m->request( GET $uri, 'If-Match' => $etag );
is($res->code, HTTP_PRECONDITION_FAILED, "HTTP_PRECONDITION_FAILED");
is($res->header('Last-Modified'), $htime,   "Last-Modified");
ok(!defined $res->header('Expires'), "Expires");
is($res->header('ETag'), "W/${etag}", "ETag");
$m->content_is("", 'no content');

# Test that header is ignored

$uri = URI->new('http://localhost/');
$uri->query_form( 'Last-Modified' => $htime, 'strong' => 1, 'Status' => HTTP_NOT_FOUND );

$res = $m->request( GET $uri, 'If-Match' => '*' );
is($res->code, HTTP_NOT_FOUND, "HTTP_NOT_FOUND");
is($res->header('Last-Modified'), $htime,   "Last-Modified");
ok(defined $res->header('Expires'), "Expires");
is($res->header('ETag'), $etag, "ETag");
$m->content_like(qr/Content[ ]Ok/, 'expected text');

$res = $m->request( GET $uri, 'If-Match' => '"xyzzy"' );
is($res->code, HTTP_NOT_FOUND, "HTTP_NOT_FOUND");
is($res->header('Last-Modified'), $htime,   "Last-Modified");
ok(defined $res->header('Expires'), "Expires");
is($res->header('ETag'), $etag, "ETag");
$m->content_like(qr/Content[ ]Ok/, 'expected text');

done_testing;
