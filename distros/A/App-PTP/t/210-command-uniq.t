#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use AppPtpTest;
use File::Temp;
use Test::More tests => 4;

{
  is(ptp(['--uniq'], \"foo\nbar\nbar\nfoo\n"), "foo\nbar\nfoo\n", 'uniq');
}{
  is(ptp(['--sort', '--uniq'], \"foo\nbar\nbar\nfoo\n"), "bar\nfoo\n", 'sort uniq');
}{
  is(ptp(['--guniq'], \"foo\nbar\nbar\nfoo\n"), "foo\nbar\n", 'global-uniq');
}{
  is(ptp(['-p', '$m=$.', '--guniq', '-n', '$m'], \"foo\nbar\nbar\nfoo\nbaz\n"), "1\n2\n5\n", 'global-uniq preserve markers');
}