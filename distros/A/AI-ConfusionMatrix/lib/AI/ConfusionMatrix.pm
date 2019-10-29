package AI::ConfusionMatrix;
$AI::ConfusionMatrix::VERSION = '0.010';
use strict;
use warnings;
use Carp;
use Exporter 'import';
our @EXPORT= qw (getConfusionMatrix makeConfusionMatrix);
use strict;
use Tie::File;

# ABSTRACT: Make a confusion matrix

sub makeConfusionMatrix {
    my ($matrix, $file, $delem) = @_;
    unless(defined $delem) {
        $delem = ',';
    }

    carp ('First argument must be a hash reference') if ref($matrix) ne 'HASH';

    my %cmData = genConfusionMatrixData($matrix);
    # This ties @output_array to the output file. Each output_array item represents a line in the output file
    tie my @output_array, 'Tie::File', $file or carp "$!";
    # Empty the file
    @output_array = ();

    my @columns = @{$cmData{columns}};
    map {$output_array[0] .= $delem . $_} join $delem, (@columns, 'TOTAL', 'TP', 'FP', 'FN', 'SENS', 'ACC');
    my $line = 1;
    my @expected = sort keys %{$matrix};
    for my $expected (@expected) {
        $output_array[$line] = $expected;
        my $lastIndex = 0;
        my $index;
        for my $predicted (sort keys %{$matrix->{$expected}}) {
            # Calculate the index of the label in the output_array of columns
            $index = _findIndex($predicted, \@columns);
            # Print some of the delimiter to get to the column of the next value predicted
            $output_array[$line] .= $delem x ($index - $lastIndex) . $matrix->{$expected}{$predicted};
            $lastIndex = $index;
        }

        # Get to the columns of the stats
        $output_array[$line] .= $delem x (scalar(@columns) - $lastIndex + 1);
        $output_array[$line] .= join $delem, (
                                    $cmData{stats}{$expected}{'total'},
                                    $cmData{stats}{$expected}{'tp'},
                                    $cmData{stats}{$expected}{'fp'},
                                    $cmData{stats}{$expected}{'fn'},
                                    sprintf('%.2f%%', $cmData{stats}{$expected}{'sensitivity'}),
                                    sprintf('%.2f%%', $cmData{stats}{$expected}{'acc'})
                                   );
        ++$line;
    }
    # Print the TOTAL row to the csv file
    $output_array[$line] = 'TOTAL' . $delem;
    map {$output_array[$line] .= $cmData{totals}{$_} . $delem} (@columns);
    $output_array[$line] .= join $delem, (
                                $cmData{totals}{'total'},
                                $cmData{totals}{'tp'},
                                $cmData{totals}{'fp'},
                                $cmData{totals}{'fn'},
                                sprintf('%.2f%%', $cmData{totals}{'sensitivity'}),
                                sprintf('%.2f%%', $cmData{totals}{'acc'})
                            );

    untie @output_array;
}

sub getConfusionMatrix {
    my ($matrix) = @_;

    carp ('First argument must be a hash reference') if ref($matrix) ne 'HASH';
    return genConfusionMatrixData($matrix);
}

sub genConfusionMatrixData {
    my $matrix = shift;
    my @expected = sort keys %{$matrix};
    my %stats;
    my %totals;
    my @columns;
    for my $expected (@expected) {
        $stats{$expected}{'fn'} = 0;
        $stats{$expected}{'tp'} = 0;
        # Ensure that the False Positive counter is defined to be able to compute the total later
        unless(defined $stats{$expected}{'fp'}) {
            $stats{$expected}{'fp'} = 0;
        }
        for my $predicted (keys %{$matrix->{$expected}}) {
            $stats{$expected}{'total'} += $matrix->{$expected}->{$predicted};
            $stats{$expected}{'tp'} += $matrix->{$expected}->{$predicted} if $expected eq $predicted;
            if ($expected ne $predicted) {
                $stats{$expected}{'fn'} += $matrix->{$expected}->{$predicted};
                $stats{$predicted}{'fp'} += $matrix->{$expected}->{$predicted};
            }
            $totals{$predicted} += $matrix->{$expected}->{$predicted};
            # Add the label to the array of columns if it does not contain it already
            push @columns, $predicted unless _findIndex($predicted, \@columns);
        }

        $stats{$expected}{'acc'} = ($stats{$expected}{'tp'} * 100) / $stats{$expected}{'total'};
    }

    for my $expected (@expected) {
        $totals{'total'} += $stats{$expected}{'total'};
        $totals{'tp'}    += $stats{$expected}{'tp'};
        $totals{'fn'}    += $stats{$expected}{'fn'};
        $totals{'fp'}    += $stats{$expected}{'fp'};
        $stats{$expected}{'sensitivity'} = ($stats{$expected}{'tp'} * 100) / ($stats{$expected}{'tp'} + $stats{$expected}{'fp'});
    }

    $totals{'acc'} = ($totals{'tp'} * 100) / $totals{'total'};
    $totals{'sensitivity'} = ($totals{'tp'} * 100) / ($totals{'tp'} + $totals{'fp'});

    return (
        columns => [sort @columns],
        stats   => \%stats,
        totals  => \%totals
    );
}

sub _findIndex {
    my ($string, $array) = @_;
    for (0 .. @$array - 1) {
        return $_ + 1 if ($string eq @{$array}[$_]);
    }
}

=head1 NAME

AI::ConfusionMatrix - make a confusion matrix

=head1 SYNOPSIS

    my %matrix;

    # Loop over your predictions
    # [...]

    $matrix{$expected}{$predicted} += 1;

    # [...]

    makeConfusionMatrix(\%matrix, 'output.csv');


=head1 DESCRIPTION

This module prints a L<confusion matrix|https://en.wikipedia.org/wiki/Confusion_matrix> from a hash reference. This module tries to be generic enough to be used within a lot of machine learning projects.

=head3 Functions:

=head4 C<makeConfusionMatrix($hash_ref, $file [, $delimiter ])>

This function makes a confusion matrix from C<$hash_ref> and writes it to C<$file>. C<$file> can be a filename or a file handle opened with the C<w+> mode. If C<$delimiter> is present, it is used as a custom separator for the fields in the confusion matrix.

Examples:

    makeConfusionMatrix(\%matrix, 'output.csv');
    makeConfusionMatrix(\%matrix, 'output.csv', ';');
    makeConfusionMatrix(\%matrix, *$fh);

The hash reference must look like this :

    $VAR1 = {
              'value_expected1' => {
                          'value_predicted1' => number_of_predictions
                        },
              'value_expected2' => {
                          'value_predicted1' => number_of_predictions,
                          'value_predicted2' => number_of_predictions
                        },
              'value_expected3' => {
                          'value_predicted3' => number_of_predictions
                        }
            };

The output will be in CSV. Here is an example:

    ,1974,1978,2002,2003,2005,TOTAL,TP,FP,FN,SENS,ACC
    1974,3,1,,,2,6,3,4,3,42.86%,50.00%
    1978,1,5,,,,6,5,4,1,55.56%,83.33%
    2002,2,2,8,,,12,8,1,4,88.89%,66.67%
    2003,1,,,7,2,10,7,0,3,100.00%,70.00%
    2005,,1,1,,6,8,6,4,2,60.00%,75.00%
    TOTAL,7,9,9,7,10,42,29,13,13,69.05%,69.05%

Prettified:

    |       | 1974 | 1978 | 2002 | 2003 | 2005 | TOTAL | TP | FP | FN | SENS    | ACC    |
    |-------|------|------|------|------|------|-------|----|----|----|---------|--------|
    | 1974  | 3    | 1    |      |      | 2    | 6     | 3  | 4  | 3  | 42.86%  | 50.00% |
    | 1978  | 1    | 5    |      |      |      | 6     | 5  | 4  | 1  | 55.56%  | 83.33% |
    | 2002  | 2    | 2    | 8    |      |      | 12    | 8  | 1  | 4  | 88.89%  | 66.67% |
    | 2003  | 1    |      |      | 7    | 2    | 10    | 7  | 0  | 3  | 100.00% | 70.00% |
    | 2005  |      | 1    | 1    |      | 6    | 8     | 6  | 4  | 2  | 60.00%  | 75.00% |
    | TOTAL | 7    | 9    | 9    | 7    | 10   | 42    | 29 | 13 | 13 | 69.05%  | 69.05% |

=over

=item TP:

True Positive

=item FP:

False Positive

=item FN:

False Negative

=item SENS

Sensitivity. Number of true positives divided by the number of positives.

=item ACC:

Accuracy

=back

=head4 C<getConfusionMatrix($hash_ref)>

Get the data used to compute the table above.

Example:

    my %cm = getConfusionMatrix(\%matrix);

=head1 AUTHOR

Vincent Lequertier <vi.le@autistici.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

# vim: set ts=4 sw=4 tw=0 fdm=marker :

