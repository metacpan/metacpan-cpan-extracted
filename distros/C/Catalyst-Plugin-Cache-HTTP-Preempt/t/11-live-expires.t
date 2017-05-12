#!/usr/bin/env perl

# Test that the Expires header is always added, but not overridden.

use strict;
use warnings;

use DateTime;
use DateTime::Format::HTTP;
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

my $uri = URI->new('http://localhost/');

my $time = DateTime::Format::HTTP->format_datetime( DateTime->now );

my $res = $m->get($uri);
ok($res->is_success, "GET " . $res->base);
is($res->header('Expires'), $time, "Expires");

$time = DateTime::Format::HTTP->format_datetime(
    DateTime->now->subtract( minutes => 123 )
);

$uri->query_form( 'Expires' => $time, );
$res = $m->get($uri);
ok($res->is_success, "GET " . $res->base);
is($res->header('Expires'), $time, "Expires");

done_testing;
