#!/usr/bin/env perl

use strict;
use warnings;

my @formats;
my $tests;

BEGIN {
    use Image::LibRSVG;
    @formats = qw(gif jpeg png bmp ico pnm xbm xpm);
    my @supp_formats = grep { Image::LibRSVG->isFormatSupported($_) } @formats;
    $tests = 1 + 4 * scalar @supp_formats; # 4 chart types
}

use Test::More tests => $tests;
use MIME::Types;

# setup library path
use FindBin qw($Bin);
use lib "$Bin/lib";

# make sure testapp works
use_ok 'TestApp';

# a live test against TestApp, the test application
use Test::WWW::Mechanize::Catalyst 'TestApp';
my $mech = Test::WWW::Mechanize::Catalyst->new;
my $t = MIME::Types->new();

foreach my $format (@formats) {
    next unless Image::LibRSVG->isFormatSupported($format);
    for my $type (qw(bar pie bar_horizontal line)) {
        my $resp = $mech->get("http://localhost/chart/$type?format=$format");
        my $ctype = $t->mimeTypeOf($format);
        is($resp->header('Content-Type'), $ctype, "Got $ctype for $type");
    }
}

done_testing;
