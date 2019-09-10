#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use AppPtpTest;
use File::Temp;
use Test::More tests => 3;

{
  is(ptp(['--pfn'], \"foo\nbar\n"), "<STDIN>\nfoo\nbar\n", 'prefix-file-name');
}{
  is(ptp(['--fn'], \"foo\nbar\n"), "<STDIN>\n", 'file-name');
}{
  is(ptp(['--fn'], \""), "", 'file-name on empty file');
}