#!/usr/bin/env perl

# 04-save-and-load.pl
#
# Training is the expensive part; scoring is cheap. The usual pattern is to fit
# a model once, persist it, and then load it elsewhere (a cron job, a service,
# another machine) to score fresh data without retraining.
#
# The module serialises to plain JSON, so a saved model is portable and
# inspectable. This script shows both the file-based API (save/load) and the
# in-memory string API (to_json/from_json), and verifies a reloaded model scores
# identically to the original.
#
#     perl -Ilib examples/save-and-load.pl

use strict;
use warnings;
use Algorithm::Classifier::IsolationForest;
use File::Temp qw(tempfile);

use constant PI => 3.14159265358979;
srand(23);

sub gaussian {
    my ( $mu, $sigma ) = @_;
    my $u1 = rand() || 1e-12;
    return $mu + $sigma * sqrt( -2 * log($u1) ) * cos( 2 * PI * rand() );
}

# --- train a model ------------------------------------------------------------
my @train = map { [ gaussian( 0, 1 ), gaussian( 0, 1 ) ] } 1 .. 400;

my $model = Algorithm::Classifier::IsolationForest->new(
    n_trees       => 100,
    sample_size   => 256,
    contamination => 0.05,
    seed          => 42,
);
$model->fit( \@train );
print "Trained a forest on ", scalar @train, " points.\n";

# Some unseen points we want to score now and again after reloading.
my @new_points = ( [ 0, 0 ], [ 1.5, -0.5 ], [ 4, 4 ], [ -5, 2 ] );
my $before = $model->score_samples( \@new_points );

# --- persist to a file --------------------------------------------------------
my ( $fh, $path ) = tempfile( 'iforest-XXXX', SUFFIX => '.json', TMPDIR => 1 );
close $fh;

$model->save($path);
printf "Saved model to %s (%d bytes of JSON).\n", $path, -s $path;

my $reloaded = Algorithm::Classifier::IsolationForest->load($path);
my $after    = $reloaded->score_samples( \@new_points );

# --- in-memory round-trip (no file) -------------------------------------------
my $json  = $model->to_json;
my $clone = Algorithm::Classifier::IsolationForest->from_json($json);
my $cloned = $clone->score_samples( \@new_points );

# --- show that everything agrees ----------------------------------------------
print "\nScoring the same unseen points three ways:\n";
printf "  %-12s  %-10s  %-12s  %-12s\n",
    'point', 'original', 'from file', 'from string';
for my $i ( 0 .. $#new_points ) {
    printf "  (%4.1f,%4.1f)  %-10.6f  %-12.6f  %-12.6f\n",
        $new_points[$i][0], $new_points[$i][1],
        $before->[$i], $after->[$i], $cloned->[$i];
}

my $identical =
    !grep { $before->[$_] != $after->[$_] || $before->[$_] != $cloned->[$_] }
    0 .. $#new_points;

print "\nReloaded scores are ",
    ( $identical ? "bit-for-bit identical to the original." : "DIFFERENT (!)" ),
    "\n";
printf "The learned threshold survived too: %.4f -> %.4f\n",
    $model->decision_threshold, $reloaded->decision_threshold;

unlink $path;
