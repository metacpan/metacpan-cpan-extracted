#!/usr/bin/env perl

# XXX Tests are incomplete since ATM only GET requests are tested XXX

use strict;
use warnings;
use Test::More tests => 23;

# setup library path
use FindBin qw($Bin);
use lib "$Bin/lib";

use HTTP::Status qw(RC_NOT_MODIFIED RC_PRECONDITION_FAILED);

my $MODIFIED_EARLIER = 'Tue, 01 Jan 2008 08:00:00 GMT';
my $MODIFIED_LATER = 'Mon, 31 Mar 2008 08:00:00 GMT';
my $GOOD_TAG = '"foo-0815-bar"';
my @BAD_TAGS = qw("foo-bar-baz" "foo-4711-bar" "S.N.A.F.U");

# make sure testapp works
use ok 'TestApp';

# a live test against TestApp, the test application
use Test::WWW::Mechanize::Catalyst 'TestApp';
my $mech = Test::WWW::Mechanize::Catalyst->new;
$mech->get_ok('http://localhost/', 'get main page');
$mech->content_like(qr/it works/i, 'see if it has our text');

# Test Etag w/ If-None-Match
$mech->get('http://localhost/etag', 'If-None-Match' => $GOOD_TAG);
is(
    $mech->res->code, RC_NOT_MODIFIED,
    'get "Not Modified" response when ETag matches value in "If-None-Match" header'
);
$mech->content_is('', 'body is empty for "Not Modified" response');

$mech->get(
    'http://localhost/etag',
    'If-None-Match' => "$BAD_TAGS[0], $GOOD_TAG, $BAD_TAGS[1]",
);
is(
    $mech->res->code, RC_NOT_MODIFIED,
    'get "Not Modified" response when Etag matches one of a list of tags in a "If-None-Match" header'
);

$mech->get('http://localhost/etag', 'If-None-Match' => '*');
is(
    $mech->res->code, RC_NOT_MODIFIED,
    'get "Not Modified" response with header "If-None-Match: *"'
);

$mech->get_ok(
    'http://localhost/etag',
    {'If-None-Match' => $BAD_TAGS[0]},
    'get uncached entity if ETag does not match'
);

$mech->get_ok(
    'http://localhost/etag',
    {'If-None-Match' => "$BAD_TAGS[0], $BAD_TAGS[2]"},
    'get uncached entity if no ETags match'
);

$mech->get_ok(
    'http://localhost/',
    {'If-None-Match' => $GOOD_TAG},
    'get uncached entity with header "If-None-Match" if resource has no entity tag'
);

# Test Etag w/ If-Match
$mech->get_ok(
    'http://localhost/etag',
    {'If-Match' => $GOOD_TAG},
    'get uncached entity if Etag matches header "If-Match"'
);

$mech->get_ok(
    'http://localhost/etag',
    {'If-Match' => "$BAD_TAGS[0], $GOOD_TAG, $BAD_TAGS[1]"},
    'get uncached entity if Etag matches one of a list in header "If-Match"'
);

$mech->get_ok(
    'http://localhost/etag',
    {'If-Match' => '*'},
    'get uncached entity for header "If-Match: *"'
);

$mech->get(
    'http://localhost/etag',
    'If-Match' => $BAD_TAGS[0],
);
is(
    $mech->res->code, RC_PRECONDITION_FAILED,
    'get "Precondition Failed" response if ETag does not match header "If-Match"'
);

$mech->get(
    'http://localhost/etag',
    'If-Match' => "$BAD_TAGS[1], $BAD_TAGS[2]"
);
is(
    $mech->res->code, RC_PRECONDITION_FAILED,
    'get "Precondition Failed" response if no ETag matches a list in header "If-Match"'
);

$mech->get('http://localhost/', 'If-Match' => $GOOD_TAG);
is(
    $mech->res->code, RC_PRECONDITION_FAILED,
    'get "Precondition Failed" response with header "If-Match" if resource has no entity tag'
);

# Test Last-Modified w/ If-Modified-Since
$mech->get(
    'http://localhost/last_modified',
    'If-Modified-Since' => $MODIFIED_LATER
);
is(
    $mech->res->code, RC_NOT_MODIFIED,
    'get "Not Modified" response if "If-Modified-Since" > "Last-Modified"'
);

$mech->get_ok(
    'http://localhost/last_modified',
    {'If-Modified-Since' => $MODIFIED_EARLIER},
    'get uncached entity if "If-Modified-Since" < "Last-Modified"'
);

$mech->get_ok(
    'http://localhost/',
    {'If-Modified-Since' => $MODIFIED_LATER},
    'get uncached entity if response has no header "Last-Modified"'
);

# Test Last-Modified w/ If-Unmodified-Since
$mech->get_ok(
    'http://localhost/last_modified',
    {'If-Unmodified-Since' => $MODIFIED_LATER},
    'get uncached entity if "If-Unmodified-Since" > "Last-Modified"'
);

$mech->get(
    'http://localhost/last_modified',
    'If-Unmodified-Since' => $MODIFIED_EARLIER
);

# Test Etag w/ If-None-Match and Last-Modified w/ If-Modified-Since
$mech->get(
    'http://localhost/all',
    'If-None-Match' => $GOOD_TAG,
    'If-Modified-Since' => $MODIFIED_LATER
);
is(
    $mech->res->code, RC_NOT_MODIFIED,
    'get "Not Modified" response if ETag matches "If-None-Match" ' .
    'and "If-Unmodified-Since" > "Last-Modified"'
);

$mech->get_ok(
    'http://localhost/all',
    {
	'If-None-Match' => $GOOD_TAG,
	'If-Modified-Since' => $MODIFIED_EARLIER,
    },
    'get uncached entity if ETag matches "If-None-Match", ' .
    'but "If-Unmodified-Since" < "Last-Modified"'
);

$mech->get_ok(
    'http://localhost/all',
    {
	'If-None-Match' => $BAD_TAGS[1],
	'If-Modified-Since' => $MODIFIED_LATER,
    },
    'get uncached entity if ETag does not match "If-None-Match", ' .
    'but "If-Unmodified-Since" > "Last-Modified"'
);

