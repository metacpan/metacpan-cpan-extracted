#!/usr/bin/perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use AppPtpTest;
use File::Temp;
use Test::More tests => 5;

{
  my $temp = File::Temp->new();
  my $f = $temp->filename;
  ptp(['-Q', '--tee', $f], \"foo\nbar\nbaz\n");
  is(slurp($f), "foo\nbar\nbaz\n", 'works');
}{
  my $temp = File::Temp->new();
  my $f = $temp->filename;
  print $temp "some content\n";
  ptp(['-Q', '--tee', $f], \"foo\nbar\nbaz\n");
  is(slurp($f), "foo\nbar\nbaz\n", 'clean content');
}{
  my $temp = File::Temp->new();
  my $f = $temp->filename;
  ptp(['-Q', '-p', 'chop', '--tee', $f, '-p', 'chop', '--tee', $f],
      \"foo\nbar\nbaz\n");
  is(slurp($f), "fo\nba\nba\nf\nb\nb\n", 'can append');
}{
  my $temp = File::Temp->new(SUFFIX => '.001');
  my $f = $temp->filename =~ s/\.001//r;
  $f =~ s/\\/\\\\/g;  # In case we're on a platform using '\' in paths.
  ptp(['-e', '$s = spf "%03d", $I', '--tee', "$f.\$s"], \"foo\nbar\n");
  is(slurp($temp->filename), "foo\nbar\n", 'compute output');
}{
  my $temp = File::Temp->new(SUFFIX => '.$s');
  my $f = $temp->filename =~ s/\.\$s//r;
  ptp(['-e', '$s = spf "%03d", $I', '-Q', '--tee', "$f.\$s"], \"foo\nbar\n");
  is(slurp($temp->filename), "foo\nbar\n", 'quote output');
}
