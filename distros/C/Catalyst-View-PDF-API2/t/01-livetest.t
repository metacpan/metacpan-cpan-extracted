#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 4;

# setup library path
use FindBin qw($Bin);
use lib "$Bin/lib";

# make sure testapp works
use_ok 'TestApp';

# a live test against TestApp, the test application
use Test::WWW::Mechanize::Catalyst 'TestApp';
my $mech = Test::WWW::Mechanize::Catalyst->new;
$mech->get_ok('http://localhost/', 'get main page');
$mech->content_like(qr/it works/i, 'see if it has our text');
$mech->get_ok('http://localhost/pdf_test/', 'pdf test');
