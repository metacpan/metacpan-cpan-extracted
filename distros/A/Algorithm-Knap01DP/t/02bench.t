# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Algorithm-Knap01DP.t'

#########################
use strict;
use Test::More  tests => 1 +   # load module
                         1     # different sizes
                         ;
use Benchmark;
BEGIN { use_ok('Algorithm::Knap01DP'); }

### main
# Compare solutions given by Algorithm::Knap01DP and Algorithm::Knapsack
SKIP: {
  eval { require Algorithm::Knapsack };
  skip "Algorithm::Knapsack not installed", 1 if $@;
  srand(7);
  my $knap = Algorithm::Knap01DP->GenKnap;
  $knap->solutions(); 
  my $knap2 = Algorithm::Knapsack->new (capacity => $knap->{capacity}, weights => $knap->{weights});
  $knap2->compute();
  my @solutions = $knap2->solutions();
  my $sol = 0;
  map { $sol += $knap->{weights}[$_] } @{$solutions[0]};
  is ($sol, $knap->{tableval}[-1][-1], 
        "Algorithm::Knap01DP gives the same sol than Algorithm::Knapsack");

  print "Benchmarking Algorithm::Knap01DP versus Algorithm::Knapsack\n";
  timethese(1, 
    {
      Knap01DP => sub { $knap->solutions(); },
      Knapsack => sub { 
        $knap2->compute();
        my @solutions = $knap2->solutions();
        my $sol = 0;
        map { $sol += $knap->{weights}[$_] } @{$solutions[0]};
      }
    }
  );
}

