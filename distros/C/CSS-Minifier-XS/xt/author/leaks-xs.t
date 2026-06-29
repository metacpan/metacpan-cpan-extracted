#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use CSS::Minifier::XS qw(minify);

BEGIN {
  eval "use Linux::Smaps";
  plan skip_all => "Linux::Smaps required for XS leak testing" if $@;
}
use Linux::Smaps;

###############################################################################
my $ITERS_WARMUP  = 100;
my $ITERS_TESTING = 5_000;

###############################################################################
# CSS input that triggers the leak: a string that minifies down to no nodes.
my $css = '/* */';

###############################################################################
# Sanity check: minify() of the test CSS returns nothing (as it was all
# minified away).
is minify($css), undef, 'minify() of empty CSS returns undef';

###############################################################################
# Warm things up.  Runs a handful of iterations so that our memory allocator
# can reach a steady state.
minify($css) for (1 .. $ITERS_WARMUP);

###############################################################################
# Measure RSS growth over repeated calls to the minifier.  If the XS code is
# leaking any memory, our RSS should grow.
my $smaps = Linux::Smaps->new;

my $rss_before = $smaps->update->rss;
minify($css) for (1 .. $ITERS_TESTING);
my $rss_after = $smaps->update->rss;

my $rss_growth = $rss_after - $rss_before;
note sprintf(
  "RSS before: %d KB, after: %d KB, growth: %d KB over %d calls (%.3f KB/call)",
  $rss_before,
  $rss_after,
  $rss_growth,
  $ITERS_TESTING,
  $rss_growth / $ITERS_TESTING,
);

###############################################################################
# Allow for some memory allocator noise and fragmentation.
#
# If total growth exceeds this threshold, odds are high that we're leaking.
my $THRESHOLD_KB = 4_000;
cmp_ok $rss_growth, '<', $THRESHOLD_KB,
  "minify() does not leak memory (RSS growth $rss_growth KB < $THRESHOLD_KB KB)";

###############################################################################
done_testing();
