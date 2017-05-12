
#!/usr/local/bin/perl -w
use strict;
use lib ('../blib/lib/', 'blib/lib/');;
use AI::NeuralNet::Simple;

my $net = AI::NeuralNet::Simple->new(2,1,2);
for (1 .. 100000) {
    $net->train([1,1],[0,1]);
    $net->train([1,0],[0,1]);
    $net->train([0,1],[0,1]);
    $net->train([0,0],[1,0]);
}

printf "Answer: %d\n",   $net->winner([1,1]);
printf "Answer: %d\n",   $net->winner([1,0]);
printf "Answer: %d\n",   $net->winner([0,1]);
printf "Answer: %d\n\n", $net->winner([0,0]);
use Data::Dumper;
print Dumper $net->infer([1,1]);
