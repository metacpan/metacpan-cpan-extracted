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
use CSS::Compressor;
use CSS::Minifier qw();
use CSS::Minifier::XS qw();
use CSS::Packer;
use File::Which qw(which);
use IO::File;
use Benchmark qw(countit);

###############################################################################
# Only run Comparison if asked for.
unless ($ENV{BENCHMARK}) {
    plan skip_all => 'Skipping Benchmark; use BENCHMARK=1 to run';
}

###############################################################################
# How long are we allowing each compressor to run?
my $time = 5;

###############################################################################
# What CSS docs do we want to try compressing?
my $curl = which('curl');
my @libs = qw(
    https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.css
);

###############################################################################
# Go grab the CSS documents, compress them, and spit out results to compare.
foreach my $uri (@libs) {
    subtest $uri => sub {
        my $content = qx{$curl --silent $uri};
        ok defined $content, 'fetched CSS';
        BAIL_OUT("No CSS fetched!") unless (length($content));

        # CSS::Packer
        do_compress('CSS::Packer', $content, sub {
            my $css = shift;
            CSS::Packer::minify(\$css);
            return $css;
        } );

        # CSS::Compressor
        do_compress('CSS::Compressor', $content, sub {
            my $css    = shift;
            my $small  = CSS::Compressor::css_compress($css);
            return $small;
        } );

        # CSS::Minifier
        do_compress('CSS::Minifier', $content, sub {
            my $css = shift;
            my $small = CSS::Minifier::minify(input => $css);
            return $small;
        } );

        # CSS::Minifier::XS
        do_compress('CSS::Minifier::XS', $content, sub {
            my $css   = shift;
            my $small = CSS::Minifier::XS::minify($css);
            return $small;
        } );
    };
}

###############################################################################
done_testing();




sub do_compress {
    my $name = shift;
    my $css  = shift;
    my $cb   = shift;

    # Compress the CSS
    my $small;
    my $count = countit($time, sub { $small = $cb->($css) } );

    # Stuff the compressed CSS out to file for examination
    my $fname = lc($name);
    $fname =~ s{\W+}{-}g;
    my $fout  = IO::File->new(">$fname.out");
    $fout->print($small);

    # Calculate length, speed, and percent savings
    my $before   = length($css);
    my $after    = length($small);
    my $rate     = sprintf('%ld', ($count->iters / $time) * $before);
    my $savings  = sprintf('%0.2f%%', (($before - $after) / $before) * 100);

    pass "$name: before[$before] after[$after] savings[$savings] rate[$rate Bytes/sec]";
}
