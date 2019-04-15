#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use AppPtpTest;
use Test::More tests => 9;

{
  my $with_final_separator = ptp([], 'simple_with_final_separator.txt');
  is($with_final_separator, "foo\nbar\n", 'final separator stdin');
} {
  my $no_final_separator = ptp([], 'simple_no_final_separator.txt');
  is($no_final_separator, "foo\nbar", 'no final separator stdin');
} {
  my $final_separator_fixed =
      ptp([qw(--fix-final-separator)], 'simple_no_final_separator.txt');
  is($final_separator_fixed, "foo\nbar\n", 'fixed final separator');
} {
  my $cat_no_sep_in_the_midle =
      ptp(['simple_no_final_separator.txt',
           'simple_with_final_separator.txt']);
  is($cat_no_sep_in_the_midle, "foo\nbarfoo\nbar\n",
     'no separator in the midle');
} {
  my $cat_no_sep_at_the_end =
      ptp(['simple_with_final_separator.txt',
           'simple_no_final_separator.txt']);
  is($cat_no_sep_at_the_end, "foo\nbar\nfoo\nbar", 'no final separator');
} {
  my $fix_no_sep_in_the_midle =
      ptp(['simple_no_final_separator.txt',
           'simple_with_final_separator.txt',
           '--fix-final-separator']);
  is($fix_no_sep_in_the_midle, "foo\nbar\nfoo\nbar\n", 'fix middle separator');
} {
  my $fix_no_sep_at_the_end =
      ptp(['simple_with_final_separator.txt',
           'simple_no_final_separator.txt',
           '--fix-final-separator']);
  is($fix_no_sep_at_the_end, "foo\nbar\nfoo\nbar\n", 'fix final separator');
} {
  my $merge_no_sep_in_the_midle =
      ptp(['simple_no_final_separator.txt',
           'simple_with_final_separator.txt',
           '--merge']);
  is($merge_no_sep_in_the_midle, "foo\nbar\nfoo\nbar\n",
     'merge no middle separator');
} {
  my $merge_no_sep_at_the_end =
      ptp(['simple_with_final_separator.txt',
           'simple_no_final_separator.txt',
           '--merge']);
  is($merge_no_sep_at_the_end, "foo\nbar\nfoo\nbar",
     'merge no final separator');
}
