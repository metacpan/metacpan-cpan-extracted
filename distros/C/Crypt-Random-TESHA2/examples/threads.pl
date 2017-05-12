#!/usr/bin/env perl
use strict;
use warnings;

use Config;
BEGIN {
  if (! $Config{useithreads} || $] < 5.008) {
    print("1..0 # Skip Threads not supported\n");
    exit(0);
  }
  if (! eval { require threads }) {
    print "1..0 # Skip threads.pm not installed\n";
    exit 0;
  }
}

use Crypt::Random::TESHA2 qw/random_bytes/;

my $numthreads = 16;
my $tsub = sub {
  #return join("", map { random_bytes(1) } 1 .. 1024);
  return random_bytes(4096);
};

my @threads;
# Fire off all our threads
push @threads, threads->create($tsub) for (1..$numthreads);
# Get results
my @rstrs;
push @rstrs, $_->join() for (@threads);

my $stri = '';
foreach my $i (0 .. length($rstrs[0])-1) {
  $stri .= substr($_, $i, 1) for @rstrs;
}

print "entropy: ";
printf "%.1f ", entropy($_) for @rstrs;
print "\n";
print "entropy for str interl: ", entropy($stri), "\n";

sub entropy {
  my @vars = map { ord($_) } split(//, $_[0]);
  my $total = scalar @vars;
  # Compute simple entropy H
  my %freq;
  $freq{$_}++ for @vars;
  my $H = 0;
  foreach my $f (values %freq) {
    my $p = $f / $total;
    $H += $p * log($p);
  }
  $H = -$H / log(2);
  return $H;
}
