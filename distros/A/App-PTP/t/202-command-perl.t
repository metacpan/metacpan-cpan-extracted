#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use AppPtpTest;
use Test::More tests => 11;

{
  my $data = ptp([qw(-p s/o/a/)], 'default_small.txt');
  is($data, "faobar\nfaobaz\n\nlast\n", '--perl');
}{
  my $data = ptp([qw(-n s/o/a/)], 'default_small.txt');
  is($data, "1\n1\n\n\n", '-n wrong');
}{
  my $data = ptp([qw(-n s/o/a/r)], 'default_small.txt');
  is($data, "faobar\nfaobaz\n\nlast\n", '-n correct');
}{
  my $data = ptp([qw(-f /o/)], 'default_small.txt');
  is($data, "foobar\nfoobaz\n", 'filter');
}{
  my $data = ptp([qw(-V -f /o/)], 'default_small.txt');
  is($data, "\nlast\n", 'filter inversed');
}{
  my $data = ptp(['-p', '$_ = 2 if $n == 2'], 'default_small.txt');
  is($data, "foobar\n2\n\nlast\n", '$n');
}{
  my $data = ptp(['-p', '$s++ if /o/; $_ = $s unless /o/'],
                 'default_small.txt');
  is($data, "foobar\nfoobaz\n2\n2\n", 'reused var');
}{
  my $data = ptp(['--mark-line', '/o/' , '-p','$_.=$. if $m'],
                 'default_small.txt');
  is($data, "foobar1\nfoobaz2\n\nlast\n", '$m');
}{
  my ($out, $err) = ptp(['-p', 'die if $. == 2; $_.="z"'], \"foo\nbar\nbaz\n");
  subtest 'die in -p', sub {
    is($out, "fooz\nbar\nbazz\n");
    ok($err =~ qr/Perl code failed in --perl/);
  }
}{
  my ($out, $err) = ptp(['-n', 'die if $. == 2; 42'], \"foo\nbar\nbaz\n");
  subtest 'die in -n', sub {
    is($out, "42\nbar\n42\n");
    ok($err =~ qr/Perl code failed in -n/);
  }
}{
  my ($out, $err) = ptp(['-f', 'die if $. == 2; 0'], \"foo\nbar\nbaz\n");
  subtest 'die in -f', sub {
    is($out, "bar\n");
    ok($err =~ qr/Perl code failed in --filter/);
  }
}