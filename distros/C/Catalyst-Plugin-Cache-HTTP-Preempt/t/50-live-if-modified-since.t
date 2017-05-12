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
$uri->query_form( 'Last-Modified' => $htime );

my $res;

$res = $m->request( GET $uri, 'If-Modified-Since' =>
		       DateTime::Format::HTTP->format_datetime(
			   $time->add( seconds => 1)
		       ) );
ok($res->is_success, "HTTP_OK");
is($res->header('Last-Modified'), $htime,   "Last-Modified");
ok(defined $res->header('Expires'), "Expires");
ok(defined $res->header('ETag'), "ETag");
$m->content_like(qr/Content[ ]Ok/, 'expected text');

$res = $m->request( GET $uri, 'If-Modified-Since' => $htime );
is($res->code, HTTP_NOT_MODIFIED, "HTTP_NOT_MODIFIED");
is($res->header('Last-Modified'), $htime,   "Last-Modified");
ok(!defined $res->header('Expires'), "not Expires");
ok(defined $res->header('ETag'), "ETag");

$res = $m->request( GET $uri, 'If-Modified-Since' =>
		       DateTime::Format::HTTP->format_datetime(
			   $time->subtract( seconds => 1)
		       ) );
is($res->code, HTTP_NOT_MODIFIED, "HTTP_NOT_MODIFIED");
is($res->header('Last-Modified'), $htime,   "Last-Modified");
ok(!defined $res->header('Expires'), "no Expires");
ok(defined $res->header('ETag'), "ETag");

$res = $m->request( GET $uri,
		    'Range' => 'bytes=0-499',
		    'If-Modified-Since' =>
		       DateTime::Format::HTTP->format_datetime(
			   $time->subtract( seconds => 1)
		       ) );
ok($res->is_success, "HTTP_OK");
is($res->header('Last-Modified'), $htime,   "Last-Modified");
ok(defined $res->header('Expires'), "Expires");
ok(defined $res->header('ETag'), "ETag");
$m->content_like(qr/Content[ ]Ok/, 'expected text');

done_testing;
