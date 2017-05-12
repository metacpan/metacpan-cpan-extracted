[![Build Status](https://travis-ci.org/wang-q/AlignDB-IntSpanXS.svg?branch=master)](https://travis-ci.org/wang-q/AlignDB-IntSpanXS)

# NAME

AlignDB::IntSpanXS - XS version of AlignDB::IntSpan.

# SYNOPSIS

    use AlignDB::IntSpanXS;

    my $set = AlignDB::IntSpanXS->new;
    $set->add(1, 2, 3, 5, 7, 9);
    $set->add_range(100, 1_000_000);
    print $set->as_string, "\n";    # 1-3,5,7,9,100-1000000

## Operator overloads

Can't overload as bool or number.

    print "$set\n";     # stringizes to the run list

# AUTHOR

Qiang Wang &lt;wang-q@outlook.com>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Qiang Wang.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
