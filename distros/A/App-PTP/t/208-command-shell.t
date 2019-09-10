#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use AppPtpTest;
use File::Temp;
use Test::More;

unless ($^O =~ /cygwin|linux/) {
  plan skip_all => 'Shell tests disabled on non-linux-like platform.';
}

{
  my $temp = File::Temp->new();
  my $f = $temp->filename;
  ptp(['--shell', "cat > $f"], \"foo\nbar\nbaz\n");
  is(slurp($f), "foo\nbar\nbaz\n", 'works');
}{
  my $temp = File::Temp->new();
  my $f = $temp->filename;
  my $out = ptp(['--shell', "cat > $f"], \"foo\nbar\nbaz\n");
  is($out, "foo\nbar\nbaz\n", 'does not change output');
}{
  my $temp = File::Temp->new();
  my $f = $temp->filename;
  my $out = ptp(['--shell', "cat > $f", '--eat'], \"foo\nbar\nbaz\n");
  is($out, "", 'eat');
}{
  my $temp = File::Temp->new();
  my $f = $temp->filename;
  my $out = ptp(['--shell', "echo \"foo\" > $f"], \"foo\nbar\nbaz\n");
  is(slurp($f), "foo\n", 'command with quote');
}{
  my $temp = File::Temp->new();
  my $f = $temp->filename;
  my $out = ptp(['-Q', '--shell', "echo \"foo\" > $f"], \"foo\nbar\nbaz\n");
  is(slurp($f), "foo\n", 'escape command with quote');
}{
  my $temp = File::Temp->new();
  my $f = $temp->filename;
  my $out = ptp(['-e', '$a = "abc"', '--shell', "echo \"\$a\" > $f"], \"foo\nbar\nbaz\n");
  is(slurp($f), "abc\n", 'interpolate variable');
}

done_testing();
