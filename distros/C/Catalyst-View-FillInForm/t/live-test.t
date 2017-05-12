#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 6;

# setup library path
use lib "t/lib";

# 1 make sure testapp works
use_ok 'TestApp';
use_ok 'TestApp::View::TT';

# a live test against TestApp, the test application
use Test::WWW::Mechanize::Catalyst 'TestApp';
my $mech = Test::WWW::Mechanize::Catalyst->new;

$mech->get_ok('http://localhost/', 'get main page');
$mech->content_like(qr/Doe/i, 'see if it has our text');

$mech->get_ok('http://localhost/alt', 'get alt page');
$mech->content_like(qr/Muffet/i, 'see if it has our text');

