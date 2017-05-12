package AI::ConfusionMatrix;
$AI::ConfusionMatrix::VERSION = '0.006';
use Carp;
use Exporter 'import';
our @EXPORT= qw (makeConfusionMatrix);
use strict;
use Tie::File;
use warnings;

# ABSTRACT: Make a confusion matrix

sub makeConfusionMatrix {
    my ($matrix, $file) = @_;
    carp ('First argument must be a hash reference') if ref($matrix) ne 'HASH';
    tie my @array, 'Tie::File', $file or carp "$!";
    my $n = 1;
    my @columns;
    my @expected = sort keys %{$matrix};
    my %stats;
    my %totals;
    for my $expected (@expected) {
        $array[$n] = $expected;
        ++$n;
        $stats{$expected}{'fn'} = 0;
        $stats{$expected}{'tp'} = 0;
        # Ensure that the False Positive counter is defined to be able to compute the total later
        unless(defined $stats{$expected}{'fp'}) {
            $stats{$expected}{'fp'} = 0;
        }
        for my $predicted (keys %{$matrix->{$expected}}) {
            $stats{$expected}{'total'} += $matrix->{$expected}->{$predicted};
            $stats{$expected}{'tp'} += $matrix->{$expected}->{$predicted} if $expected == $predicted;
            if ($expected != $predicted) {
                $stats{$expected}{'fn'} += $matrix->{$expected}->{$predicted};
                $stats{$predicted}{'fp'} += $matrix->{$expected}->{$predicted};
            }
            $totals{$predicted} += $matrix->{$expected}->{$predicted};
            # Add the label to the array of columns if it does not contain it already
            push @columns, $predicted unless _findIndex($predicted, \@columns);
        }

        $stats{$expected}{'acc'} = sprintf("%.2f", ($stats{$expected}{'tp'} * 100) / $stats{$expected}{'total'});
    }

    for my $expected (@expected) {
        $totals{'total'} += $stats{$expected}{'total'};
        $totals{'tp'}    += $stats{$expected}{'tp'};
        $totals{'fn'}    += $stats{$expected}{'fn'};
        $totals{'fp'}    += $stats{$expected}{'fp'};
        $stats{$expected}{'acc'} .= '%';
    }

    $totals{'acc'} = sprintf("%.2f%%", ($totals{'tp'} * 100) / $totals{'total'});
    @columns = sort @columns;
    map {$array[0] .= ',' . $_} join ',', (@columns, 'TOTAL', 'TP', 'FP', 'FN', 'ACC');
    $n = 1;
    for my $expected (@expected) {
        my $lastIndex = 0;
        my $index;
        for my $predicted (sort keys %{$matrix->{$expected}}) {
            # Calculate the index of the label in the array of columns
            $index = _findIndex($predicted, \@columns);
            # Print some commas to get to the column of the next value predicted
            $array[$n] .= ',' x ($index - $lastIndex) . $matrix->{$expected}{$predicted};
            $lastIndex = $index;
        }

        # Get to the columns of the stats
        $array[$n] .= ',' x (scalar(@columns) - $lastIndex + 1);
        $array[$n] .= join ',', (
            $stats{$expected}{'total'},
            $stats{$expected}{'tp'},
            $stats{$expected}{'fp'},
            $stats{$expected}{'fn'},
            $stats{$expected}{'acc'}
        );
        ++$n;
    }
    # Print the TOTAL row to the csv file
    $array[$n] = 'TOTAL,';
    map {$array[$n] .= $totals{$_}. ','} (sort keys %totals)[0 .. $#columns];
    $array[$n] .= join ',', ($totals{'total'}, $totals{'tp'}, $totals{'fp'}, $totals{'fn'}, $totals{'acc'});

    untie @array;
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

    Loop over your tests

    ---

    $matrix{$expected}{$predicted} += 1;

    ---

    makeConfusionMatrix(\%matrix, 'output.csv');


=head1 DESCRIPTION

This module prints a L<confusion matrix|https://en.wikipedia.org/wiki/Confusion_matrix> from a hash reference. This module tries to be generic enough to be used within a lot of machine learning projects.

=head3 Function

=head4 C<makeConfusionMatrix($hash_ref, $file)>

This function makes a confusion matrix from C<$hash_ref> and writes it to C<$file>. C<$file> can be a filename or a file handle opened with the C<w+> mode.

Examples:

    makeConfusionMatrix(\%matrix, 'output.csv');
    makeConfusionMatrix(\%matrix, *$fh);

The hash reference must look like this :

    $VAR1 = {


              'value_expected1' => {
                          'value_predicted1' => value
                        },
              'value_expected2' => {
                          'value_predicted1' => value,
                          'value_predicted2' => value
                        },
              'value_expected3' => {
                          'value_predicted3' => value
                        }

            };

The output will be in CSV. Here is an example:


    ,1997,1998,2001,2003,2005,2008,2012,2015,TOTAL,TP,FP,FN,ACC
    1997,2,,,,,,,,2,2,0,0,100.00%
    1998,,1,,,,,,,1,1,0,0,100.00%
    2001,,,1,,,,,,1,1,0,0,100.00%
    2003,,,,5,,,1,1,7,5,0,2,71.43%
    2005,,,,,7,,,2,9,7,0,2,77.78%
    2008,,,,,,3,,,3,3,0,0,100.00%
    2012,,,,,,,5,,5,5,1,0,100.00%
    2015,,,,,,,,8,8,8,3,0,100.00%
    TOTAL,2,1,1,5,7,3,6,11,36,32,4,4,88.89%

Prettified:

    |       | 1997 | 1998 | 2001 | 2003 | 2005 | 2008 | 2012 | 2015 | TOTAL | TP | FP | FN | ACC     |
    |-------|------|------|------|------|------|------|------|------|-------|----|----|----|---------|
    | 1997  | 2    |      |      |      |      |      |      |      | 2     | 2  | 0  | 0  | 100.00% |
    | 1998  |      | 1    |      |      |      |      |      |      | 1     | 1  | 0  | 0  | 100.00% |
    | 2001  |      |      | 1    |      |      |      |      |      | 1     | 1  | 0  | 0  | 100.00% |
    | 2003  |      |      |      | 5    |      |      | 1    | 1    | 7     | 5  | 0  | 2  | 71.43%  |
    | 2005  |      |      |      |      | 7    |      |      | 2    | 9     | 7  | 0  | 2  | 77.78%  |
    | 2008  |      |      |      |      |      | 3    |      |      | 3     | 3  | 0  | 0  | 100.00% |
    | 2012  |      |      |      |      |      |      | 5    |      | 5     | 5  | 1  | 0  | 100.00% |
    | 2015  |      |      |      |      |      |      |      | 8    | 8     | 8  | 3  | 0  | 100.00% |
    | TOTAL | 2    | 1    | 1    | 5    | 7    | 3    | 6    | 11   | 36    | 32 | 4  | 4  | 88.89%  |

=over

=item TP:

True Positive

=item FP:

False Positive

=item FN:

False Negative

=item ACC:

Accuracy

=back

=head1 AUTHOR

Vincent Lequertier <sky@riseup.net>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

# vim: set ts=4 sw=4 tw=0 fdm=marker :

