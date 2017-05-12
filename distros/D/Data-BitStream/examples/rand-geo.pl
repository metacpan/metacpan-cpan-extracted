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
use BitStreamTest;
use POSIX;

my $type = 'wordvec';

# Time with small, big, and mixed numbers.

sub ceillog2 {
  my $v = shift;
  $v--;
  my $b = 1;
  $b++  while ($v >>= 1);
  $b;
}

my @encodings = qw|
  gamma
  bvzeta(2)
  fib
  ber
  varint
  deltagol(11)
  arice(0)
  omegagol(11)
  ss(3-1-3)
  gg(6)
  eg(3)
  sss(3-1-10)
  baer(1)
  golomb(6)
  ss(3-0-0-1-3)
  rice(3)
|;

my $list_n = 10000;
my @list;

srand(15);
sub rand_geo {
  my $param = shift;
  my $N = shift;

  # Inspired by Bio::Tools::RandomDistFunctions (Jason Stajich, Mike Sanderson)
  # Any misuse of their function is purely my fault.
  my $den;
  if( $param < 1e-8) { 
      $den = (-1 * $param) - ( $param * $param ) / 2;
  } else { 
      $den = log(1 - $param);
  }
  my $z = log(1 - rand(1)) / $den;
  $z = POSIX::floor($z) + 1;
  $z = $N if $z > $N;
  return $z;
}

{
  push @list, rand_geo(0.1, 65535)  for (1 .. $list_n);
}
print "List holds ", scalar @list, " numbers\n";

#@list = shuffle(@list);
# average value
my $avg = int((sum @list) / scalar @list);
# bytes required in fixed size (FOR encoding)
my $bytes = int(ceillog2(max @list) * scalar @list / 8);

#push @encodings, 'golomb(' . int(0.69 * $avg) . ')';

if (0) {
  my $minsize = 140000;
  my $maxval = max @list;
  foreach my $p1 (0 .. 8) {
  foreach my $p2 (0 .. 8) {
    next unless ($p1 + $p2) <= 8;
    next unless BitStream::Code::StartStop::max_code_for_startstop([$p1,$p2]) >= $maxval;
    my $stream = stream_encode_array($type, "ss($p1-$p2)", @list);
    my $len = $stream->len;
    if ($len < $minsize) {
      print "new min:  $len   ss($p1-$p2)\n";
      $minsize = $len;
    }
  }
  }
  foreach my $p1 (0 .. 8) {
  foreach my $p2 (0 .. 8) {
  foreach my $p3 (0 .. 8) {
    next unless ($p1 + $p2 + $p3) <= 8;
    next unless BitStream::Code::StartStop::max_code_for_startstop([$p1,$p2,$p3]) >= $maxval;
    my $stream = stream_encode_array($type, "ss($p1-$p2-$p3)", @list);
    my $len = $stream->len;
    if ($len < $minsize) {
      print "new min:  $len   ss($p1-$p2-$p3)\n";
      $minsize = $len;
    }
  }
  }
  }
  foreach my $p1 (0 .. 8) {
  foreach my $p2 (0 .. 8) {
  foreach my $p3 (0 .. 8) {
  foreach my $p4 (0 .. 8) {
    next unless ($p1 + $p2 + $p3 + $p4) <= 8;
    next unless BitStream::Code::StartStop::max_code_for_startstop([$p1,$p2,$p3,$p4]) >= $maxval;
    my $stream = stream_encode_array($type, "ss($p1-$p2-$p3-$p4)", @list);
    my $len = $stream->len;
    if ($len < $minsize) {
      print "new min:  $len   ss($p1-$p2-$p3-$p4)\n";
      $minsize = $len;
    }
  }
  }
  }
  }
  foreach my $p1 (0 .. 8) {
  foreach my $p2 (0 .. 8) {
  foreach my $p3 (0 .. 8) {
  foreach my $p4 (0 .. 8) {
  foreach my $p5 (0 .. 8) {
    next unless ($p1 + $p2 + $p3 + $p4 + $p5) <= 8;
    next unless BitStream::Code::StartStop::max_code_for_startstop([$p1,$p2,$p3,$p4, $p5]) >= $maxval;
    my $stream = stream_encode_array($type, "ss($p1-$p2-$p3-$p4-$p5)", @list);
    my $len = $stream->len;
    if ($len < $minsize) {
      print "new min:  $len   ss($p1-$p2-$p3-$p4-$p5)\n";
      $minsize = $len;
    }
  }
  }
  }
  }
  }
}


print "List (avg $avg, max ", max(@list), ", $bytes binary):\n";
time_list($_, @list) for (@encodings);

sub time_list {
  my $encoding = shift;
  my @list = @_;
  my $s1 = [gettimeofday];
  my $stream = stream_encode_array($type, $encoding, @list);
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

