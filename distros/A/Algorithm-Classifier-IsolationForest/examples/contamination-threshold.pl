#!/usr/bin/env perl

# 03-contamination-threshold.pl
#
# Picking an anomaly score cutoff by hand is fiddly. If you can estimate what
# fraction of your data is anomalous, pass it as `contamination` and fit() will
# learn a threshold that flags about that fraction of the training set. predict()
# then uses that learned threshold by default, so you never have to guess a
# number.
#
#     perl -Ilib examples/contamination-threshold.pl

use strict;
use warnings;
use Algorithm::Classifier::IsolationForest;
use List::Util qw(sum);

use constant PI => 3.14159265358979;
srand(11);

sub gaussian {
	my ( $mu, $sigma ) = @_;
	my $u1 = rand() || 1e-12;
	return $mu + $sigma * sqrt( -2 * log($u1) ) * cos( 2 * PI * rand() );
}

# 480 normal points + 20 outliers => the true anomaly rate is 20/500 = 4%.
my @data;
push @data, [ gaussian( 0, 1 ), gaussian( 0, 1 ) ] for 1 .. 480;
for ( 1 .. 20 ) {
	my $a = rand() * 2 * PI;
	my $r = 6 + rand() * 2;
	push @data, [ $r * cos($a), $r * sin($a) ];
}

# Tell the forest we expect ~4% anomalies.
my $iforest = Algorithm::Classifier::IsolationForest->new(
	n_trees       => 100,
	sample_size   => 256,
	contamination => 0.04,
	seed          => 42,
);

# Before fitting there is no threshold yet.
printf "decision_threshold before fit(): %s\n",
	defined $iforest->decision_threshold ? $iforest->decision_threshold : 'undef';

$iforest->fit( \@data );

printf "decision_threshold learned by fit(): %.4f\n\n", $iforest->decision_threshold;

# predict() with no arguments uses the learned threshold.
my $auto   = $iforest->predict( \@data );
my $n_auto = sum(@$auto);

# Compare with the naive fixed 0.5 cutoff on the very same model.
my $fixed   = $iforest->predict( \@data, 0.5 );
my $n_fixed = sum(@$fixed);

printf "Flagged with the learned threshold : %d / %d points (%.1f%%)\n", $n_auto,  scalar @data, 100 * $n_auto / @data;
printf "Flagged with a fixed 0.5 threshold : %d / %d points (%.1f%%)\n", $n_fixed, scalar @data, 100 * $n_fixed / @data;
printf "\n(true anomaly rate baked into the data: %.1f%%)\n",            100 * 20 / @data;

print <<'NOTE';

Takeaways:
  * decision_threshold() exposes whatever fit() learned (undef if you never set
    contamination).
  * predict() with no threshold uses that learned cutoff; pass an explicit
    threshold to override it for a single call.
  * Set contamination to your best guess of the anomaly fraction -- it doesn't
    have to be exact, it just calibrates where the cutoff lands.
NOTE
