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
use Data::BitStream::XS;
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
  gamma
  boldivigna(2)
  fibonacci
  deltagol(11)
  arice(0)
  omegagol(11)
  startstop(3-1-3)
  gammagolomb(6)
  expgolomb(3)
  startstepstop(3-1-10)
  baer(1)
  golomb(6)
  startstop(3-0-0-1-3)
  rice(3)
|;

# Register these codes with the D:B:XS code_* routines, so we can reference
# them by name.
Data::BitStream::XS::add_code(
    { package   => __PACKAGE__,
      name      => 'DeltaGol',
      universal => 1,
      params    => 1,
      encodesub => sub {shift->put_golomb( sub {shift->put_delta(@_)}, @_ )},
      decodesub => sub {shift->get_golomb( sub {shift->get_delta(@_)}, @_ )}, }
);
Data::BitStream::XS::add_code(
    { package   => __PACKAGE__,
      name      => 'OmegaGol',
      universal => 1,
      params    => 1,
      encodesub => sub {shift->put_golomb( sub {shift->put_omega(@_)}, @_ )},
      decodesub => sub {shift->get_golomb( sub {shift->get_omega(@_)}, @_ )}, }
);

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

print "List (avg $avg, max ", max(@list), ", $bytes binary):\n";
time_list($_, @list) for (@encodings);

sub time_list {
  my $encoding = shift;
  my @list = @_;
  my $stream = Data::BitStream::XS->new;
  my $s1 = [gettimeofday];
  $stream->code_put($encoding, @list);
  my $e1 = int(tv_interval($s1)*1_000_000);
  my $len = $stream->len;
  my $s2 = [gettimeofday];
  $stream->rewind_for_read;
  my @a = $stream->code_get($encoding, -1);
  my $e2 = int(tv_interval($s2)*1_000_000);
  foreach my $i (0 .. $#list) {
      die "incorrect $encoding coding for $i" if $a[$i] != $list[$i];
  }
  printf "   %-14s:  %8d bytes  %8d uS encode  %8d uS decode\n",
         $encoding, int(($len+7)/8), $e1, $e2;
  1;
}

