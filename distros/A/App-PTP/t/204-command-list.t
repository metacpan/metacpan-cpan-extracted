#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use AppPtpTest;
use Test::More tests => 8;

{
  my $data = ptp([qw(--head 2)], 'default_data.txt');
  is($data, "test\nfoobar=\n", 'head');
}{
  my $data = ptp([qw(--head)], 'default_data.txt');
  is($data, "test\nfoobar=\nab/cd\nBe\nfoobaz\n.\\+\n\nlast=\nlast\n",
     'head default');
}{
  my $data = ptp([qw(--head -5)], 'default_data.txt');
  is($data, "test\nfoobar=\nab/cd\nBe\n", 'head negative');
}{
  my $data = ptp([qw(--head -15)], 'default_data.txt');
  is($data, '', 'head nothing left negative');
}{
  my $data = ptp([qw(--tail 2)], 'default_data.txt');
  is($data, "last=\nlast\n", 'tail');
}{
  my $data = ptp([qw(--tail)], 'default_data.txt');
  is($data, "test\nfoobar=\nab/cd\nBe\nfoobaz\n.\\+\n\nlast=\nlast\n",
     'tail default');
}{
  my $data = ptp([qw(--tail -5)], 'default_data.txt');
  is($data, ".\\+\n\nlast=\nlast\n", 'tail negative');
}{
  my $data = ptp([qw(--tail -15)], 'default_data.txt');
  is($data, '', 'tail nothing left negative');
}
