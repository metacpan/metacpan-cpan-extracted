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

#### `makeConfusionMatrix($hash_ref, $file)`

This function makes a confusion matrix from `$hash_ref` and writes it to `$file`. `$file` can be a filename or a file handle opened with the `w+` mode.

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

- TP:

    True Positive

- FP:

    False Positive

- FN:

    False Negative

- ACC:

    Accuracy

# AUTHOR

Vincent Lequertier <sky@riseup.net>

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
