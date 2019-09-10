#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use AppPtpTest;
use Test::More tests => 2;

{
  is(ptp(['-0'], \"foo\n\x00bar\n"), "foo\nbar\n", 'null input separator');
}{
  is(ptp(['-00'], \"foo\nbar\n"), "foo\x00bar\x00", 'null output separator');
}