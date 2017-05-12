NAME
    Data::FormValidator::Constraints::MethodsFactory - Create constraints
    for Data::FormValidator

SYNOPSIS
      use Data::FormValidator::Constraints::MethodsFactory qw(:set :num :bool);

      # SET constraints (:set)
      constraint_methods => {
          status        => FV_set(1, qw(new active disabled)),
          how_many      => FV_set_num(1, (1 .. 20)),
          province      => FV_set_word(1, "AB QC ON TN NU"),
          seen_before   => FV_set_cmp(1, sub { $seen{$_[0]} }, qw(foo bar)),
      }

      # NUMERIC constraints (:num)
      constraint_methods => {
          how_many      => FV_clamp(1, 1, 10),
          small_amount  => FV_lt(1, 3),
          large_amount  => FV_gt(1, 10),
          small_again   => FV_le(1, 3),
          large_again   => FV_ge(1, 10),
      }

      # BOOLEAN constraints (:bool)
      constraint_methods => {
          bad_status    => FV_not(
                                FV_set(1, qw(new active disabled))
                                ),
          email         => FV_or(
                                FV_set(1,$current_value),
                                Data::FormValidator::Constraints::email(),
                                ),
          password      => FV_and(
                                FV_length_between(6,32),
                                my_password_validation_constraint(),
                                ),
      }

DESCRIPTION
    "Data::FormValidator::Constraints::MethodsFactory" provides a variety of
    functions that can be used to generate constraint closures for use with
    "Data::FormValidator".

    The functions/constraints provided are based on those from
    "Data::FormValidator::ConstraintsFactory", BUT are designed to be used
    as "new-style" constraints (while
    "Data::FormValidator::ConstraintsFactory" was designed for use with
    "old-style" constraints). Functionally, this module provides equivalents
    for all of the constraints that were in
    "Data::FormValidator::ConstraintsFactory", but if you're trying to do
    things with the new-style you'll want to use the versions from this
    module instead.

    The constraints provided by this module are broken up into three main
    categories/sections:

    Set constraints (:set)
        Constraint methods for working with "sets" of data. Useful for when
        you want to check and make sure that the provided value is from a
        list of valid choices.

        The following constraints are exported via the ":set" tag:

            FV_set
            FV_set_num
            FV_set_word
            FV_set_cmp

    Numeric constraints (:num)
        Constraint methods for working with numbers. Useful when you want to
        check and make sure that the provided value is within a specified
        range.

        The following constraints are exported via the ":num" tag:

            FV_clamp
            FV_lt
            FV_gt
            FV_le
            FV_ge

    Boolean constraints (:bool)
        Constraint methods for working with boolean conditions. Useful when
        you want to combine constraints together to create much more
        powerful constraints (e.g. validating an e-mail address to make sure
        that it looks valid and has an associated MX record, BUT only if the
        value actually changed from what we had in the record previously).

        The following constraints are exported via the ":bool" tag:

            FV_not
            FV_or
            FV_and

METHODS
    FV_set($result, @set)
        Creates a constraint closure that will return the provided $result
        if the value is a member of the given @set, or the negation of
        $result otherwise.

        The "eq" operator is used for comparison.

    FV_set_num($result, @set)
        Creates a constraint closure that will return the provided $result
        if the value is a member of the given @set, or the negation of
        $result otherwise.

        The "==" operator is used for comparison.

    FV_set_word($result, $set)
        Creates a constraint closure that will return the provided $result
        if the value is a word in the given $set, or the negation of $result
        otherwise.

    FV_set_cmp($result, $cmp, @set)
        Creates a constraint closure that will return the provided $result
        if the value is a member of the given @set, or the negation of
        $result otherwise.

        $cmp is a function which takes two arguments, and should return true
        if the two elements are considered equal, otherwise returning false.

    FV_clamp($result, $low, $high)
        Creates a constraint closure that will return the provided $result
        if the value is numerically between the given $low and $high bounds,
        or the negation of $result otherwise.

    FV_lt($result, $bound)
        Creates a constraint closure that will return the provided $result
        if the value is numerically less than the given $bound, or the
        negation of $result otherwise.

    FV_gt($result, $bound)
        Creates a constraint closure that will return the provided $result
        if the value is numerically greater than the given $bound, or the
        negation of $result otherwise.

    FV_le($result, $bound)
        Creates a constraint closure that will return the provided $result
        if the value is numerically less than or equal to the given $bound,
        or the negation of $result otherwise.

    FV_ge($result, $bound)
        Creates a constraint closure that will return the provided $result
        if the value is numerically greater than or equal to the given
        $bound, or the negation of $result otherwise.

    FV_not($constraint)
        Creates a constraint closure that will return the negation of the
        result of the given $constraint.

    FV_or(@constraints)
        Creates a constraint closure that will return the result of the
        first constraint that returns a non-false result.

    FV_and(@constraints)
        Creates a constraint closure that will return the result of the
        first constraint to return a non-false result, -IF- ALL of the
        constraints return non-false results.

AUTHOR
    Graham TerMarsch (cpan@howlingfrog.com)

COPYRIGHT
    Copyright (C) 2007, Graham TerMarsch. All Rights Reserved.

    This is free software; you can redistribute it and/or modify it under
    the same license as Perl itself.

SEE ALSO
    Data::FormValidator.

