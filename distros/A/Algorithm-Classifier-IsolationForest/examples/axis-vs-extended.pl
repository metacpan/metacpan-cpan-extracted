#!/usr/bin/env perl

# axis-vs-extended.pl
#
# Isolation Forest comes in two flavours here:
#   mode => 'axis'      classic, axis-parallel splits (the original algorithm)
#   mode => 'extended'  Extended Isolation Forest, random *hyperplane* splits
#
# Axis-parallel splits can only cut straight across one feature at a time, which
# leaves a rectangular, axis-aligned bias in the score field. On data whose
# features are correlated (a diagonal band), that bias shows up two ways:
#   * points that sit off the diagonal but still inside each feature's range
#     get under-scored by axis mode, and
#   * points on the diagonal can get spuriously inflated scores.
# Extended mode, using oblique cuts, softens both effects.
#
# This script trains one forest of each kind on the same diagonal band and
# compares how they score a few hand-picked probe points.
#
#     perl -Ilib examples/axis-vs-extended.pl

use strict;
use warnings;
use Algorithm::Classifier::IsolationForest;

srand(3);    # reproducible data

# A tight band along the line y = x, with both features spanning roughly [-3, 3].
my @data;
for ( 1 .. 400 ) {
    my $t = -3 + 6 * rand();
    push @data, [ $t + 0.05 * ( rand() - 0.5 ), $t + 0.05 * ( rand() - 0.5 ) ];
}

my $axis = Algorithm::Classifier::IsolationForest->new(
    mode => 'axis', n_trees => 200, sample_size => 256, seed => 1 )->fit( \@data );

my $ext = Algorithm::Classifier::IsolationForest->new(
    mode => 'extended', n_trees => 200, sample_size => 256, seed => 1 )
    ->fit( \@data );

# name => [x, y], with a note on what we expect
my @probes = (
    [ 'on the line, centre',   [ 0,  0 ],  'normal' ],
    [ 'on the line, far end',  [ 3,  3 ],  'edge of normal' ],
    [ 'off-diagonal, in range',[ 3,  -3 ], 'ANOMALY (within each axis range)' ],
    [ 'off-diagonal, in range',[ -3, 3 ],  'ANOMALY (within each axis range)' ],
    [ 'far outside everything',[ 10, 10 ], 'ANOMALY (obvious)' ],
);

print "Anomaly scores (higher = more anomalous), trained on a diagonal band:\n\n";
printf "  %-26s %-11s  %-6s  %-9s  %s\n",
    'probe point', '(x, y)', 'axis', 'extended', 'note';
print '  ', '-' x 78, "\n";

for my $p (@probes) {
    my ( $name, $xy, $note ) = @$p;
    my $a = $axis->score_samples( [$xy] )->[0];
    my $e = $ext->score_samples(  [$xy] )->[0];
    printf "  %-26s (%-3g,%3g)  %-6.3f  %-9.3f  %s\n",
        $name, $xy->[0], $xy->[1], $a, $e, $note;
}

print <<'NOTE';

What to notice:
  * On the off-diagonal anomalies, extended mode scores *higher* than axis mode
    -- it sees them as the outliers they are, even though each coordinate by
    itself is unremarkable.
  * On the diagonal points, extended mode scores a touch *lower*: it isn't fooled
    into inflating scores along the axis-aligned grain of the data.
Extended mode tends to help whenever your features are correlated or the normal
region isn't a neat axis-aligned box.
NOTE
