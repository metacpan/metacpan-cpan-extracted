use strict;
use Test::Simple tests => 6;
#TODO: not use Test::Simple;

use Algorithm::Knapsack;

my @weights = (14, 5, 2, 11, 3, 8);
my $knapsack = Algorithm::Knapsack->new(capacity => 30, weights => \@weights);
ok(defined($knapsack) && ref($knapsack) eq 'Algorithm::Knapsack',
   'new() works');

$knapsack->compute();

my @solutions = $knapsack->solutions();
ok($#solutions == 2, 'found 3 solutions');
ok(join(',', @{ $solutions[0] }) eq '0,1,3',   'first solution is correct');
ok(join(',', @{ $solutions[1] }) eq '0,1,4,5', 'second solution is correct');
ok(join(',', @{ $solutions[2] }) eq '0,2,3,4', 'third solution is correct');

ok($knapsack->{emptiness} == 0, 'emptiness is 0');
