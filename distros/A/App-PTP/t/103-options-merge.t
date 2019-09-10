#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use AppPtpTest;
use Test::More tests => 2;

{
  is(ptp(['--merge', 'default_small.txt', 'default_small.txt', '--sort', '--uniq']),
         "\nfoobar\nfoobaz\nlast\n", 'merge');
}{
  is(ptp(['--merge'], \"foo\nbar\n"), "foo\nbar\n", 'merge stdin');
}