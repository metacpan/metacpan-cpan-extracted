#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use AppPtpTest;
use Test::More tests => 4;

{
  # qw  would emit a warning because of the use of commas.
  my $data = ptp(['--cut', '1,3,4'], \"1,2,3\na\tb\nX,Y,Z,T\n");
  is($data, "1\t3\t\na\t\t\nX\tZ\tT\n", 'cut');
}{
  my $data = ptp(['--csv', '--cut', '2,3'], \"1 , 2\t3\na, b, c\n");
  is($data, "2\t3,\nb,c\n", 'csv');
}{
  my $data = ptp(['--tsv', '--cut', '2,3'], \"1\t2 , 3\na\tb\tc\n");
  is($data, "2 , 3\t\nb\tc\n", 'tsv');
}{
  my $data = ptp(['--byte', '--cut', '2,4'], \"hélôa\n.\t,z\n");
  is($data, "éô\n\tz\n", 'byte');
}
