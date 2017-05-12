#!/usr/bin/perl
use strict;
use warnings;

# The purpose of this test is to ensure the implementation keeps all its
# data stored in instance data, and nothing is shared among streams.

eval {require List::Util; 1;} or do {
  sub shuffle (@) {
    my @a=\(@_);
    my $n;
    my $i=@_;
    map {
      $n = rand($i--);
      (${$a[$n]}, $a[$n] = $a[$i])[0];
    } @_;
  }
};
use Test::More;
use Data::BitStream::XS qw(code_is_universal);
my @encodings = qw|
              Unary Unary1 Gamma Delta Omega
              Fibonacci FibGen(3) EvenRodeh Levenstein
              Golomb(10) Golomb(16) Golomb(14000)
              Rice(2) Rice(9)
              GammaGolomb(3) GammaGolomb(128) ExpGolomb(5)
              BoldiVigna(2) Baer(0) Baer(-2) Baer(2)
              StartStepStop(3-3-99) StartStop(1-0-1-0-2-12-99)
              ARice(2)
            |;


my $nstreams = 7;
my $nvals    = 50;

plan tests => scalar @encodings;

foreach my $encoding (@encodings) {

  srand(12);
  my @stream_data;   # array of arrays holding random integers
  my @streams;       # array of stream objects
  my @nstream;       # array of stream numbers, one per value

  # Create data and streams
  foreach my $stream_number (1 .. $nstreams) {
    foreach my $n (1 .. $nvals) {
      $stream_data[$stream_number][$n] = int(rand(1000));
      push @nstream, $stream_number;
    }
    $streams[$stream_number] = Data::BitStream::XS->new;
  }

  # Now insert the data into interleaved streams, random ordering
  {
    my @stream_counter;
    foreach my $sn (shuffle @nstream) {
      $stream_counter[$sn]++;
      my $v = $stream_data[$sn][$stream_counter[$sn]];
      $streams[$sn]->code_put( $encoding, $v );
      # close each stream as it is done
      $streams[$sn]->write_close if $stream_counter[$sn] >= $nvals;
    }
  }

  # Now read the interleaved streams in another random ordering
  {
    my $success = 1;
    my @stream_counter;
    foreach my $sn (shuffle @nstream) {
      $stream_counter[$sn]++;
      # open each stream as we come to it
      $streams[$sn]->rewind if $stream_counter[$sn] == 1;
      my $v = $streams[$sn]->code_get($encoding);
      my $orig = $stream_data[$sn][$stream_counter[$sn]];
      #is($v, $orig, "interleaved $encoding coding, value $stream_counter[$sn] of stream $sn/$nstreams");
      $success = 0 if $v != $orig;
    }
    ok($success, "interleaved $encoding coding ($nstreams streams)");
  }
}
