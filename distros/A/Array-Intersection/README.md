# NAME

Array::Intersection - Calculates the intersection of two array references

# SYNOPSIS

    use Array::Intersection;
    my @intersection = intersection([1,2,3,4], [3,4,5,6]); #expect (3,4)

# DESCRIPTION

This package exports the intersection() function which uses the magic of a hash slice to return an intersection of the data.

## LIMITATIONS

Hash keys are strings so numeric data like 1 and 1.0 will be uniqued away in the string folding process. However, the function folds undef into a unique string so that it supports both empty string "" and undef.

## FUNCTIONS

## intersection

This intersection function uses a hash slice method to determine the intersection between the first array reference and the second array reference.

    my @intersection = intersection([1,2,3,4], [3,4,5,6]); #expect (3,4)
    my @intersection = intersection(\@array_1, \@array_2);

# SEE ALSO

https://perldoc.perl.org/perlfaq4#How-do-I-compute-the-difference-of-two-arrays?-How-do-I-compute-the-intersection-of-two-arrays?
[List::MoreUtils](https://metacpan.org/pod/List%3A%3AMoreUtils)

# AUTHOR

Michael R. Davis

# COPYRIGHT AND LICENSE

Copyright (C) 2024 by Michael R. Davis

MIT
