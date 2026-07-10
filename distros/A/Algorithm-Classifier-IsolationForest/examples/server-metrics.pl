#!/usr/bin/env perl

# 05-server-metrics.pl
#
# A more applied example: spotting odd requests in server telemetry. Each sample
# is [latency_ms, response_bytes]. Most traffic is well-behaved; a few requests
# are slow and/or return a weird payload size. We fit a forest, rank every
# request by anomaly score, and write the scored data out as CSV.
#
# Note the two features live on very different scales (hundreds of ms vs
# thousands of bytes). Isolation Forest splits each feature within its *own*
# observed range and never computes distances, so -- unlike k-NN or clustering
# -- you don't have to standardise the columns first.
#
#     perl -Ilib examples/server-metrics.pl

use strict;
use warnings;
use Algorithm::Classifier::IsolationForest;

use constant PI => 3.14159265358979;
srand(99);

sub gaussian {
	my ( $mu, $sigma ) = @_;
	my $u1 = rand() || 1e-12;
	return $mu + $sigma * sqrt( -2 * log($u1) ) * cos( 2 * PI * rand() );
}

# --- synthesise some telemetry ------------------------------------------------
# 200 healthy requests: ~120 ms, ~2000 byte responses.
my @requests;
push @requests, [ gaussian( 120, 20 ), gaussian( 2000, 300 ) ] for 1 .. 200;

# A handful of injected problems, each a different shape of "weird":
my @injected = (
	[ 850, 2100 ],    # very slow, normal-ish payload
	[ 770, 2050 ],    # very slow
	[ 130, 9000 ],    # normal latency, huge payload
	[ 125, 60 ],      # normal latency, tiny/empty payload
	[ 680, 150 ],     # slow AND tiny payload
);
push @requests, @injected;

# --- fit ----------------------------------------------------------------------
my $iforest = Algorithm::Classifier::IsolationForest->new(
	n_trees       => 150,
	sample_size   => 256,
	contamination => 0.03,    # we suspect ~3% of traffic is off
	seed          => 7,
);
$iforest->fit( \@requests );

# score_samples -> anomaly score in (0,1]; path_lengths -> mean isolation depth.
# They move in opposite directions: a *short* average path means the point was
# easy to isolate, which means a *high* score.
my $scores = $iforest->score_samples( \@requests );
my $depths = $iforest->path_lengths( \@requests );
my $flags  = $iforest->predict( \@requests );

printf "Scored %d requests; learned threshold = %.3f\n\n", scalar @requests, $iforest->decision_threshold;

# --- rank and show the worst offenders ----------------------------------------
my @order = sort { $scores->[$b] <=> $scores->[$a] } 0 .. $#requests;

print "Most anomalous requests:\n";
printf "  %-10s  %-13s  %-7s  %-7s  %s\n", 'latency_ms', 'resp_bytes', 'depth', 'score', 'flagged';
print '  ', '-' x 60, "\n";
for my $i ( @order[ 0 .. 9 ] ) {
	printf "  %-10.1f  %-13.0f  %-7.2f  %-7.3f  %s\n",
		$requests[$i][0], $requests[$i][1],
		$depths->[$i], $scores->[$i],
		( $flags->[$i] ? 'YES' : '' );
}

my $n_flagged = grep { $_ } @$flags;
printf "\n%d of %d requests flagged as anomalous.\n", $n_flagged, scalar @requests;

# --- write the full scored dataset to CSV -------------------------------------
my $csv = 'request_scores.csv';
open my $out, '>', $csv or die "cannot write $csv: $!";
print {$out} "latency_ms,response_bytes,mean_path_length,anomaly_score,flagged\n";
for my $i ( 0 .. $#requests ) {
	printf {$out} "%.2f,%.0f,%.4f,%.4f,%d\n",
		$requests[$i][0], $requests[$i][1],
		$depths->[$i], $scores->[$i], ( $flags->[$i] ? 1 : 0 );
}
close $out;
print "Wrote per-request scores to $csv (open it in a spreadsheet to plot).\n";
