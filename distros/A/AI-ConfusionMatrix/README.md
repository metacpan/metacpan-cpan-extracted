# NAME

AI::ConfusionMatrix - make a confusion matrix

# SYNOPSIS

    my %matrix;

    Loop over your tests

    ---

    $matrix{$expected}{$predicted} += 1;

    ---

    makeConfusionMatrix(\%matrix, 'output.csv');

# DESCRIPTION

This module prints a [confusion matrix](https://en.wikipedia.org/wiki/Confusion_matrix) from a hash reference. This module tries to be generic enough to be used within a lot of machine learning projects.

### Function

#### `makeConfusionMatrix($hash_ref, $file [, $delimiter ])`

This function makes a confusion matrix from `$hash_ref` and writes it to `$file`. `$file` can be a filename or a file handle opened with the `w+` mode. If `$delimiter` is present, it is used as a custom separator for the fields in the confusion matrix.

Examples:

    makeConfusionMatrix(\%matrix, 'output.csv');
    makeConfusionMatrix(\%matrix, 'output.csv', ';');
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

- TP:

    True Positive

- FP:

    False Positive

- FN:

    False Negative

- SENS

    Sensitivity. Number of true positives divided by the number of positives.

- ACC:

    Accuracy

# AUTHOR

Vincent Lequertier <vi.le@autistici.org>

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
