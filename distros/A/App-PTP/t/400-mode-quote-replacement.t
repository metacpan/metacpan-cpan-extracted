#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use AppPtpTest;
use Test::More tests => 2;

{
  my $data = ptp([qw(-sq ! -p s/o/!/)], 'default_small.txt');
  is($data, "f'obar\nf'obaz\n\nlast\n", '--sq');
}{
  my $data = ptp(['--ds', '#', '--dq', '?', '-n', '#a = ?foo?; return #a'], 'one_line.txt');
  is($data, "foo\n", '--ds');
}
