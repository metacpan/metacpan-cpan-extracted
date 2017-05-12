Algorithm::Loops - Looping constructs:
    NestedLoops, MapCar*, Filter, and NextPermute*

Algorithm::Loops provides several functions for doing different types of
looping constructs:

Filter

    Similar to C<map> but designed for use with s/// and other reflexive
    operations.  Returns a modified copy of a list.

MapCar, MapCarU, MapCarE, and MapCarMin

    All similar to C<map> but loop over multiple lists at the same time.

NextPermute and NextPermuteNum

    Efficiently find all (unique) permutations of a list, even if it
    contains duplicate values.

NestedLoops

    Simulate C<foreach> loops nested arbitrarily deep.
