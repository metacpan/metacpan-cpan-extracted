#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use File::Which qw(which);
use CSS::Minifier::XS qw(minify);

BEGIN {
    eval "use Test::LeakTrace";
    plan skip_all => "Test::LeakTrace required for leak testing" if $@;
}
use Test::LeakTrace;

###############################################################################
# What CSS docs do we want to try compressing?
my $curl = which('curl');
my @libs = qw(
    https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.css
    https://stackpath.bootstrapcdn.com/bootstrap/4.4.1/css/bootstrap.css
);

###############################################################################
# Make sure we're not leaking memory when we minify
foreach my $url (@libs) {
  subtest $url => sub {
    my $css = qx{$curl --silent $url};
    ok $css, 'got some CSS to minify';
    no_leaks_ok { minify($css) } "no leaks when minifying; $url";
  };
}

###############################################################################
done_testing();
