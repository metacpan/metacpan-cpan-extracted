
# NAME

Algorithm::Prefixspan - Perl implementation for the algorithm PrefixSpan (Prefix-projected Sequential Pattern mining).

# SYNOPSIS

    use Algorithm::Prefixspan;
    my $data = [
                "a c d",
                "a b c",
                "c b a",
                "a a b",
               ];
    
    my $prefixspan = Algorithm::Prefixspan->new(
                                 data => $data,
                                );
    
    my $pattern = $prefixspan->run; 
    # $pattern got as follow.   
    # {
    #           'c' => 3,
    #           'a c' => 2,
    #           'a' => 5,
    #           'b' => 3,
    #           'a b' => 2
    # };

    options:
    # set minimum support (default: 2)
    $prefixspan->{'minsup'} = 2
    
    # set minimum pattern length (default: 1)
    $prefixspan->{'len'} = 1

# DESCRIPTION

Algorithm::Prefixspan is pure perl implementation
for the algorithm PrefixSpan (Prefix-projected Sequential Pattern mining) 
by designed Pei et al.

This module is not fast.

Reference

\* PrefixSpan: Mining Sequential Patterns Efficiently by Prefix-Projected Pattern Growth Jian Pei, Jiawei Han, Behzad Mortazavi-asl, Helen Pinto, Qiming Chen, Umeshwar Dayal and Mei-chun Hsu IEEE Computer Society, 2001, pages 215.

# LICENSE

Copyright (C) Yukio HORI.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Yukio HORI <horiyuki@cpan.org>
