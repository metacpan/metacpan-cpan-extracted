#!/usr/bin/perl -wT

use strict;
use warnings;

use Test::More tests => 3;
use lib qw( t/lib );


# Make sure the Catalyst app loads ok...
use_ok('TestApp');


# Check that the TextLinkAds model returns a valid TextLinkAds object...
my $tla = TestApp->model('TextLinkAds');
isa_ok( $tla, 'TextLinkAds' );
can_ok( $tla, 'fetch' );


# If you've already tested and installed TextLinkAds, there is no reason to
# run tests against text-link-ads.com again.


1;
