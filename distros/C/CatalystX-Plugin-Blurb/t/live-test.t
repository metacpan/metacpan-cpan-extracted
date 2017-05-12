#!/usr/bin/env perl

use strict;
use warnings;
#use Test::More tests => 3;
use Test::More "no_plan";

# setup library path
use FindBin qw($Bin);
use lib "$Bin/lib";

# make sure testapp works
use ok 'TestApp';

# a live test against TestApp, the test application
use Test::WWW::Mechanize::Catalyst 'TestApp';
my $mech = Test::WWW::Mechanize::Catalyst->new;
$mech->get_ok('http://localhost/', 'get main page');
$mech->content_like(qr/it works/i, 'see if it has our text');

$mech->get_ok('http://localhost/one', 'get /one');
$mech->content_like(qr/OK/, 'Contains "OK" blurb');

$mech->get_ok('http://localhost/one_by_two', 'get /one_by_two');
$mech->content_like(qr/moo/, 'Contains "moo" blurb');
$mech->content_like(qr/OK/, 'Contains "OK" blurb');

$mech->get_ok('http://localhost/two_by_one_flat', 'get /two_by_one_flat');
$mech->content_like(qr/moo/, 'Contains "moo" blurb');
$mech->content_like(qr/OK/, 'Contains "OK" blurb');

$mech->get_ok('http://localhost/two_by_one_ref', 'get /two_by_one_ref');
$mech->content_like(qr/moo/, 'Contains "moo" blurb');
$mech->content_like(qr/OK/, 'Contains "OK" blurb');


$mech->get_ok('http://localhost/one_ref', 'get /one_ref');
$mech->content_like(qr/OK/, 'Contains "OK" blurb');

$mech->get_ok('http://localhost/two_by_two_ref', 'get /two_by_two_ref');
$mech->content_like(qr/moo/, 'Contains "moo" blurb');
$mech->content_like(qr/OK/, 'Contains "OK" blurb');

$mech->get_ok('http://localhost/callback/one', 'get /callback/one');
$mech->content_like(qr/Arabic one/i, 'Rendered correctly');


