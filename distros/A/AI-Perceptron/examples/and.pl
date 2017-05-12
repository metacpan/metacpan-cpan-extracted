#!/usr/bin/perl
#
# And - and function using a perceptron
# Steve Purkis <spurkis@epn.nu>
# July 20, 1999
##


use Data::Dumper;
use AI::Perceptron;

print( "Example: training a perceptron to recognize an 'AND' function.\n",
       "usage: $0 [<threshold> <weight1> <weight2>]\n" );

my $p = AI::Perceptron->new
                      ->num_inputs( 2 )
                      ->learning_rate( 0.1 );
if (@ARGV) {
    $p->threshold( shift(@ARGV) )
      ->weights([ shift(@ARGV), shift(@ARGV) ]);
}

my @training_exs = (
		    [-1 => -1, -1],
		    [-1 =>  1, -1],
		    [-1 => -1,  1],
		    [ 1 =>  1,  1],
		   );

print "\nBefore Training\n";
dump_perceptron( $p );

print "\nTraining...\n";
$p->train( @training_exs );

print "\nAfter Training\n";
dump_perceptron( $p );

sub dump_perceptron {
    my $p = shift;
    print "\tThreshold: ", $p->threshold, " Weights: ", join(', ', @{ $p->weights }), "\n";
    foreach my $inputs (@training_exs) {
	my $target = $inputs->[0];
	print "\tInputs = {", join(',', @$inputs[1..2]), "}, target=$target, output=", $p->compute_output( @$inputs[1..2] ), "\n";
    }
}
