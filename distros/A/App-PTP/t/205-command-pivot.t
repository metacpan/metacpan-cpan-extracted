#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use AppPtpTest;
use Test::More tests => 4;

{
  my $data = ptp([qw(--pivot)], \"1,2,3\na,b\nX,Y,Z,T\n");
  is($data, "1,2,3\ta,b\tX,Y,Z,T\n", 'pivot');
}{
  my $data = ptp([qw(--none --transpose)], \"1,2,3\na,b\nX,Y,Z,T\n");
  is($data, "1,2,3\ta,b\tX,Y,Z,T\n", 'transpose none');
}{
  my $data = ptp([qw(--transpose)], \"1,2,3\na,b\nX,Y,Z,T\n");
  is($data, "1\ta\tX\n2\tb\tY\n3\t\tZ\n\t\tT\n", 'transpose');
}{
  my $data = ptp([qw(--anti-pivot)], \"1,2,3\na,b\nX,Y,Z,T\n");
  is($data, "1\n2\n3\na\nb\nX\nY\nZ\nT\n", 'anti-pivot');
}
