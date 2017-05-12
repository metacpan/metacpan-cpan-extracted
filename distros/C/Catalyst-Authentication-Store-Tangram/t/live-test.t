#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 2;

# setup library path
use FindBin qw($Bin);
use lib "$Bin/lib";

# a live test against TestApp, the test application
use Test::WWW::Mechanize::Catalyst 'TestApp';
my $mech = Test::WWW::Mechanize::Catalyst->new;
$mech->get_ok('http://localhost/', 'get main page');
$mech->content_like(qr/^Authenticated:\d+\. Roles: role1, role2, role3$/i, 'see if it has our text');

