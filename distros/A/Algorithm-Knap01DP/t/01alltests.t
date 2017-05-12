# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Algorithm-Knap01DP.t'

#########################
use strict;
use Test::More  tests => 1 +   # load module
                         5*2 + # 2*@inputfiles 
                         1 +   # different sizes
                         2     # random
                         ;
BEGIN { use_ok('Algorithm::Knap01DP'); }

### main
my @inputfiles = qw/knap21.dat  knap22.dat  knap23.dat  knap25.dat knapanderson.dat/;
my @sol = (280, 107, 150, 900, 30);
my $knap21 = ['102', [ '2', '20', '20', '30', '40', '30', '60', '10' ], 
                  [ '15', '100', '90', '60', '40', '15', '10', '1' ]];
my $knap22 = ['50',  [ '31', '10', '20', '19', '4', '3', '6' ], 
                  [ '70', '20', '39', '37', '7', '5', '10' ]];
my $knap23 = ['190', [ '56', '59', '80', '64', '75', '17' ],
                  [ '50', '50', '64', '46', '50', '5' ]]; 
my $knap25 = ['104', [ '25', '35', '45', '5', '25', '3', '2', '2' ],
                  [ '350', '400', '450', '20', '70', '8', '5', '5' ]];
my $knapAnderson = [30, [14, 5, 2, 11, 3, 8], [14, 5, 2, 11, 3, 8]];

my $knapsackproblem = [$knap21, $knap22, $knap23, $knap25, $knapAnderson];

my $i = 0;
my $knap;

# Now 2*@inputfiles = 10 tests
for my $file (@inputfiles) {
  $knap = Algorithm::Knap01DP->ReadKnap((-e "t/$file")?"t/$file":$file);
  is_deeply($knapsackproblem->[$i], 
            [$knap->{capacity}, $knap->{weights}, $knap->{profits}], 
            "ReadKnap $file");
  $knap->Knap01DP();
  is($sol[$i++], $knap->{tableval}[-1][-1], "Knap01DP $file");
  $knap->solutions();
  $knap->ShowResults();
}

# test to check when weights and profits do not have the same size
eval {
  $knap = Algorithm::Knap01DP->new(
            capacity => 100, weights => [ 1..5 ], profits => [1..10]);
};
like $@, qr/Profits and Weights don't have the same size/, "different sizes";

srand(7);
$knap = Algorithm::Knap01DP->GenKnap;
srand(7);
my $knap2 = Algorithm::Knap01DP->GenKnap;
is_deeply($knap, $knap2, "Random generation same seed");
my @nopos = grep { $_ <= 0 } $knap->{weights};
is(scalar(@nopos), 0, "Random: positive weights");
