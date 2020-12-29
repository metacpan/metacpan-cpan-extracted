#!/usr/bin/perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}


use strict;
use warnings;
use Test::More;
use File::Slurp qw(slurp);
use CSS::Minifier::XS qw(minify);

BEGIN {
    eval "use Test::LeakTrace";
    plan skip_all => "Test::LeakTrace required for leak testing" if $@;
    plan tests => 2;
}
use Test::LeakTrace;

###############################################################################
# Suck in a bunch of CSS to use for testing.
my $css = '';
$css .= slurp($_) for (<t/css/*.css>);
ok length($css), 'got some CSS to minify';

###############################################################################
# Make sure we're not leaking memory when we minify
no_leaks_ok { minify($css) } 'no leaks when minifying CSS';
