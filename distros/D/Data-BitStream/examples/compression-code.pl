#!/usr/bin/perl
use strict;
use warnings;
use 5.010;
use Data::Dumper;
use List::Util qw(shuffle sum max);
use Time::HiRes qw(gettimeofday tv_interval);
use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/../t/lib";
use Data::BitStream;
use BitStreamTest;
use POSIX;

# Time with small, big, and mixed numbers.

sub ceillog2 {
  my $v = shift;
  $v--;
  my $b = 1;
  $b++  while ($v >>= 1);
  $b;
}

my @encodings = qw|
  ss(0-2-7)
  unary
  ss(0-1-2-6)
  omega
  ss(0-0-1-1-7)
  levenstein
  arice(2)
  gamma
  baer(-4)
|;

# These files contain a lot of gamma encoded numbers generated from a
# multidimensional prediction algorithm.  They should be between 0 and 510,
# hence fit in 9 bits (generated from signed pixel differences).
my $file = '3d-unary.raw';
#my $file = '4d-unary.raw';
my @list;
my $listn;
{
  my $s1 = [gettimeofday];
  my $stream = Data::BitStream->new( file => $file, mode => 'ro' );
  my $e1 = int(tv_interval($s1)*1_000_000);
  my $s2 = [gettimeofday];
  @list = $stream->get_unary(-1);
  my $e2 = int(tv_interval($s2)*1_000_000);
  $listn = scalar @list;
  printf "Slurped $listn numbers in %.1f ms, decoded in %.1f ms\n", $e1/1000,$e2/1000;
}

# average value
my $avg = int( ((sum @list) / $listn) + 0.5);
# bytes required in fixed size (FOR encoding)
my $bytes = int(ceillog2(max @list) * $listn / 8);


print "List (avg $avg, max ", max(@list), ", $bytes binary):\n";
time_list($_, @list) for (@encodings);

sub time_list {
  my $encoding = shift;
  my @list = @_;
  my $s1 = [gettimeofday];
  my $stream = stream_encode_array('wordvec', $encoding, @list);
  die "Stream ($encoding) construction failure" unless defined $stream;
  my $e1 = int(tv_interval($s1)*1_000_000);
  my $len = $stream->len;
  my $s2 = [gettimeofday];
  my @a = stream_decode_array($encoding, $stream);
  my $e2 = int(tv_interval($s2)*1_000_000);
  foreach my $i (0 .. $#list) {
      die "incorrect $encoding coding for $i" if $a[$i] != $list[$i];
  }
  printf "   %-14s:  %8d bytes  %8d uS encode  %8d uS decode\n", 
         $encoding, int(($len+7)/8), $e1, $e2;
  1;
}

