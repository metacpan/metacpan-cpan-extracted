#!perl
use strict;
use warnings;
use ExtUtils::Manifest qw(fullcheck);
use Test::More tests => 2;

my ($missing, $extra) = do {
    local $ExtUtils::Manifest::Quiet = 1;
    fullcheck();
};

ok !scalar @$missing, 'No missing files that are in MANIFEST'
  or do {
      diag "No such file: $_" foreach @$missing;
  };

ok !scalar @$extra, 'No extra files that aren\'t in MANIFEST'
  or do {
      diag "Not in MANIFEST: $_" foreach @$extra;
  };
