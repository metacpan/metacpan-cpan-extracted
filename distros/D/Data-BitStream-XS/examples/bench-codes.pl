#!/usr/bin/perl
use strict;
use warnings;
use List::Util qw(shuffle sum max);
use Time::HiRes qw(gettimeofday tv_interval);
use FindBin;
use lib "$FindBin::Bin/../lib";
use Data::BitStream::XS;

# Time with small, big, and mixed numbers.

sub ceillog2 {
  my $v = shift;
  $v--;
  my $b = 1;
  $b++  while ($v >>= 1);
  $b;
}

my $add_golomb = 0;
my @encodings;

@encodings = qw|
  Gamma
  Delta
  Omega
  EvenRodeh
  Levenstein
  Fibonacci
  Unary
  Unary1
  Baer(0)
  Baer(-2)
  Baer(2)
  BoldiVigna(4)
  Golomb(3)
  Rice(2)
  ARice(2)
  Golomb(177)
  GammaGolomb(3)
  ExpGolomb(3)
  StartStop(0-0-2-4-14)
  StartStepStop(3-2-20)
  Comma(2)
  Comma(3)
  BlockTaboo(00)
  BlockTaboo(010)
  BinWord(20)
|;
@encodings = qw|Gamma Delta Omega Fibonacci Baer(-1)|;

my $list_n = 2048;
my @list_small;
my @list_medium;
my @list_large;

{
  push @list_small, 0 for (1 .. $list_n);
  push @list_small, 1 for (1 .. ($list_n /2));
  push @list_small, 2 for (1 .. ($list_n /4));
  push @list_small, 3 for (1 .. ($list_n /8));
  push @list_small, 4 for (1 .. ($list_n /16));
  push @list_small, 4 for (1 .. ($list_n /32));
  push @list_small, 5 for (1 .. ($list_n /64));
  foreach my $n (6 .. 32) {
    push @list_small, $n for (1 .. ($list_n /128));
  }
}
print "Lists hold ", scalar @list_small, " numbers\n";
srand(15);
{
  foreach my $i (1 .. scalar @list_small) {
    # skew to smaller numbers
    my $d = rand(1);
    if    ($d < 0.25) { push @list_medium, int(rand(32)); }
    elsif ($d < 0.50) { push @list_medium, int(rand(256)); }
    elsif ($d < 0.75) { push @list_medium, int(rand(1024)); }
    else              { push @list_medium, int(rand(2048)); }
  }
  foreach my $i (1 .. scalar @list_small) {
    #push @list_large, 500+int(rand(65000));
    # skew to smaller numbers
    my $d = rand(1);
    if    ($d < 0.25) { push @list_large, int(rand(32)); }
    elsif ($d < 0.50) { push @list_large, int(rand(256)); }
    elsif ($d < 0.75) { push @list_large, int(rand(16000)); }
    elsif ($d < 0.98) { push @list_large, int(rand(65000)); }
    else              { push @list_large, int(rand(1_000_000)); }
  }
}

@list_small = shuffle(@list_small);
@list_medium = shuffle(@list_medium);
@list_large = shuffle(@list_large);
# average value
my $avg_small = int((sum @list_small) / scalar @list_small);
my $avg_medium = int((sum @list_medium) / scalar @list_medium);
my $avg_large = int((sum @list_large) / scalar @list_large);
# bytes required in fixed size (FOR encoding)
my $bytes_small = int(ceillog2(max @list_small) * scalar @list_small / 8);
my $bytes_medium = int(ceillog2(max @list_medium) * scalar @list_medium / 8);
my $bytes_large = int(ceillog2(max @list_large) * scalar @list_large / 8);

if ($add_golomb) {
  push @encodings, 'golomb(' . int(0.69 * $avg_medium) . ')';
  push @encodings, 'golomb(' . int(0.69 * $avg_large) . ')';
}

my $tot_encode_time = 0;
my $tot_decode_time = 0;

print "Small (avg $avg_small, $bytes_small binary):\n";
  time_list($_, @list_small) for (@encodings);
print "Medium (avg $avg_medium, $bytes_medium binary):\n";
  time_list($_, @list_medium) for (@encodings);
print "Large (avg $avg_large, $bytes_large binary):\n";
  time_list($_, @list_large) for (@encodings);

#print "total encode: $tot_encode_time\n";
#print "total decode: $tot_decode_time\n";

sub time_list {
  my $encoding = shift;
  die "'$encoding' is unsupported"
      unless Data::BitStream::XS::code_is_supported($encoding);
  my @list = @_;
  my $s1 = [gettimeofday];

  #my $stream = stream_encode_array('wordvec', $encoding, @list);
  #die "Stream ($encoding) construction failure" unless defined $stream;

  my $stream = Data::BitStream::XS->new;
  die "Stream construction failure" unless defined $stream;
  $stream->code_put($encoding, @list);
  #foreach my $v (@list) { $stream->code_put($encoding, $v); }

  my $e1 = int(tv_interval($s1)*1_000_000);
  my $len = $stream->len;
  my $s2 = [gettimeofday];

  #my @a = stream_decode_array($encoding, $stream);

  $stream->rewind_for_read;
  my @a = $stream->code_get($encoding, -1);
  #my @a=(); while (defined (my $v = $stream->code_get($encoding))) {push @a,$v;}

  my $e2 = int(tv_interval($s2)*1_000_000);
  foreach my $i (0 .. $#list) {
      die "incorrect $encoding coding for $i" if $a[$i] != $list[$i];
  }
  # convert total uS time into ns/value
  $e1 = int(1000 * ($e1 / scalar @list));
  $e2 = int(1000 * ($e2 / scalar @list));
  printf "   %-21s: %8d bytes %8d ns encode %8d ns decode\n",
         $encoding, int(($len+7)/8), $e1, $e2;
  $tot_encode_time += $e1;
  $tot_decode_time += $e2;
  1;
}

