package AI::Calibrate;

use 5.008008;
use strict;
use warnings;

use vars qw($VERSION);
$VERSION = "1.5";

require Exporter;

our @ISA = qw(Exporter);

# This allows declaration:
#	use AI::Calibrate ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = (
    'all' => [
        qw(
              calibrate
              score_prob
              print_mapping
            )
    ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw( );

use constant DEBUG => 0;

# Structure slot names
use constant SCORE => 0;
use constant PROB  => 1;

=head1 NAME

AI::Calibrate - Perl module for producing probabilities from classifier scores

=head1 SYNOPSIS

  use AI::Calibrate ':all';
  ... train a classifier ...
  ... test classifier on $points ...
  $calibrated = calibrate($points);

=head1 DESCRIPTION

Classifiers usually return some sort of an instance score with their
classifications.  These scores can be used as probabilities in various
calculations, but first they need to be I<calibrated>.  Naive Bayes, for
example, is a very useful classifier, but the scores it produces are usually
"bunched" around 0 and 1, making these scores poor probability estimates.
Support vector machines have a similar problem.  Both classifier types should
be calibrated before their scores are used as probability estimates.

This module calibrates classifier scores using a method called the Pool
Adjacent Violators (PAV) algorithm.  After you train a classifier, you take a
(usually separate) set of test instances and run them through the classifier,
collecting the scores assigned to each.  You then supply this set of instances
to the calibrate function defined here, and it will return a set of ranges
mapping from a score range to a probability estimate.

For example, assume you have the following set of instance results from your
classifier.  Each result is of the form C<[ASSIGNED_SCORE, TRUE_CLASS]>:

 my $points = [
              [.9, 1],
              [.8, 1],
              [.7, 0],
              [.6, 1],
              [.55, 1],
              [.5, 1],
              [.45, 0],
              [.4, 1],
              [.35, 1],
              [.3, 0 ],
              [.27, 1],
              [.2, 0 ],
              [.18, 0],
              [.1, 1 ],
              [.02, 0]
             ];

If you then call calibrate($points), it will return this structure:

 [
   [.9,    1 ],
   [.7,  3/4 ],
   [.45, 2/3 ],
   [.3,  1/2 ],
   [.2,  1/3 ],
   [.02,   0 ]
  ]

This means that, given a SCORE produced by the classifier, you can map the
SCORE onto a probability like this:

               SCORE >= .9        prob = 1
         .9  > SCORE >= .7        prob = 3/4
         .7  > SCORE >= .45       prob = 2/3
         .45 > SCORE >= .3        prob = 3/4
         .2  > SCORE >= .7        prob = 3/4
         .02 > SCORE              prob = 0

For a realistic example of classifier calibration, see the test file
t/AI-Calibrate-NB.t, which uses the AI::NaiveBayes1 module to train a Naive
Bayes classifier then calibrates it using this module.

=cut

=head1 FUNCTIONS

=over 4

=item B<calibrate>

This is the main calibration function.  The calling form is:

my $calibrated = calibrate( $data, $sorted);

$data looks like: C<[ [score, class], [score, class], [score, class]...]>
Each score is a number.  Each class is either 0 (negative class) or 1
(positive class).

$sorted is boolean (0 by default) indicating whether the data are already
sorted by score.  Unless this is set to 1, calibrate() will sort the data
itself.

Calibrate returns a reference to an ordered list of references:

  [ [score, prob], [score, prob], [score, prob] ... ]

Scores will be in descending numerical order.  See the DESCRIPTION section for
how this structure is interpreted.  You can pass this structure to the
B<score_prob> function, along with a new score, to get a probability.

=cut

sub calibrate {
    my($data, $sorted) = @_;

    if (DEBUG) {
        print "Original data:\n";
        for my $pair (@$data) {
            my($score, $prob) = @$pair;
            print "($score, $prob)\n";
        }
    }

    #  Copy the data over so PAV can clobber the PROB field
    my $new_data = [ map([@$_], @$data) ];

    #   If not already sorted, sort data decreasing by score
    if (!$sorted) {
        $new_data = [ sort { $b->[SCORE] <=> $a->[SCORE] } @$new_data ];
    }

    PAV($new_data);

    if (DEBUG) {
        print("After PAV, vector is:\n");
        print_vector($new_data);
    }

    my(@result);
    my( $last_prob, $last_score);

    push(@$new_data, [-1e10, 0]);

    for my $pair (@$new_data) {
        print "Seeing @$pair\n" if DEBUG;
        my($score, $prob) = @$pair;
        if (defined($last_prob) and $prob < $last_prob) {
            print("Pushing [$last_score, $last_prob]\n") if DEBUG;
            push(@result, [$last_score, $last_prob] );
        }
        $last_prob = $prob;
        $last_score = $score;
    }

    return \@result;
}


sub PAV {
    my ( $result ) = @_;

    for ( my $i = 0; $i < @$result - 1; $i++ ) {
        if ( $result->[$i][PROB] < $result->[ $i + 1 ][PROB] ) {
            $result->[$i][PROB] =
                ( $result->[$i][PROB] + $result->[ $i + 1 ][PROB] ) / 2;
            $result->[ $i + 1 ][PROB] = $result->[$i][PROB];
            print "Averaging elements $i and ", $i + 1, "\n" if DEBUG;

            for ( my $j = $i - 1; $j >= 0; $j-- ) {
                if ( $result->[$j][PROB] < $result->[ $i + 1 ][PROB] ) {
                    my $d = ( $i + 1 ) - $j + 1;
                    flatten( $result, $j, $d );
                }
                else {
                    last;
                }
            }
        }
    }
}

sub print_vector {
    my($vec) = @_;
    for my $pair (@$vec) {
        print join(", ", @$pair), "\n";
    }
}


sub flatten {
    my ( $vec, $start, $len ) = @_;
    if (DEBUG) {
        print "Flatten called on vec, $start, $len\n";
        print "Vector before: \n";
        print_vector($vec);
    }

    my $sum = 0;
    for my $i ( $start .. $start + $len-1 ) {
        $sum += $vec->[$i][PROB];
    }
    my $avg = $sum / $len;
    print "Sum = $sum, avg = $avg\n" if DEBUG;
    for my $i ( $start .. $start + $len -1) {
        $vec->[$i][PROB] = $avg;
    }
    if (DEBUG) {
        print "Vector after: \n";
        print_vector($vec);
    }
}

=item B<score_prob>

This is a simple utility function that takes the structure returned by
B<calibrate>, along with a new score, and returns the probability estimate.
Example calling form:

  $p = score_prob($calibrated, $score);

Once you have a trained, calibrated classifier, you could imagine using it
like this:

 $calibrated = calibrate( $calibration_set );
 print "Input instances, one per line:\n";
 while (<>) {
    chomp;
    my(@fields) = split;
    my $score = classifier(@fields);
    my $prob = score_prob($score);
    print "Estimated probability: $prob\n";
 }

=cut

sub score_prob {
    my($calibrated, $score) = @_;

    my $last_prob = 1.0;

    for my $tuple (@$calibrated) {
        my($bound, $prob) = @$tuple;
        return $prob if $score >= $bound;
        $last_prob = $prob;
    }
    #  If we drop off the end, probability estimate is zero
    return 0;
}


=item B<print_mapping>

This is a simple utility function that takes the structure returned by
B<calibrate> and prints out a simple list of lines describing the mapping
created.

Example calling form:

  print_mapping($calibrated);

Sample output:

  1.00 > SCORE >= 1.00     prob = 1.000
  1.00 > SCORE >= 0.71     prob = 0.667
  0.71 > SCORE >= 0.39     prob = 0.000
  0.39 > SCORE >= 0.00     prob = 0.000

These ranges are not necessarily compressed/optimized, as this sample output
shows.

=back

=cut
sub print_mapping {
    my($calibrated) = @_;
    my $last_bound = 1.0;
    for my $tuple (@$calibrated) {
        my($bound, $prob) = @$tuple;
        printf("%0.3f > SCORE >= %0.3f     prob = %0.3f\n",
               $last_bound, $bound, $prob);
        $last_bound = $bound;
    }
    if ($last_bound != 0) {
        printf("%0.3f > SCORE >= %0.3f     prob = %0.3f\n",
               $last_bound, 0, 0);
    }
}

=head1 DETAILS

The PAV algorithm is conceptually straightforward.  Given a set of training
cases ordered by the scores assigned by the classifier, it first assigns a
probability of one to each positive instance and a probability of zero to each
negative instance, and puts each instance in its own group.  It then looks, at
each iteration, for adjacent violators: adjacent groups whose probabilities
locally increase rather than decrease.  When it finds such groups, it pools
them and replaces their probability estimates with the average of the group's
values.  It continues this process of averaging and replacement until the
entire sequence is monotonically decreasing.  The result is a sequence of
instances, each of which has a score and an associated probability estimate,
which can then be used to map scores into probability estimates.

For further information on the PAV algorithm, you can read the section in my
paper referenced below.

=head1 EXPORT

This module exports three functions: calibrate, score_prob and print_mapping.

=head1 BUGS

None known.  This implementation is straightforward but inefficient (its time
is O(n^2) in the length of the data series).  A linear time algorithm is
known, and in a later version of this module I'll probably implement it.

=head1 SEE ALSO

The AI::NaiveBayes1 perl module.

My paper "PAV and the ROC Convex Hull" has a good discussion of the PAV
algorithm, including examples:
L<http://home.comcast.net/~tom.fawcett/public_html/papers/PAV-ROCCH-dist.pdf>

If you want to read more about the general issue of classifier calibration,
here are some good papers, which are freely available on the web:

I<"Transforming classifier scores into accurate multiclass probability estimates">
by Bianca Zadrozny and Charles Elkan

I<"Predicting Good Probabilities With Supervised Learning">
by A. Niculescu-Mizil and R. Caruana


=head1 AUTHOR

Tom Fawcett, E<lt>tom.fawcett@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2012 by Tom Fawcett

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
1;
