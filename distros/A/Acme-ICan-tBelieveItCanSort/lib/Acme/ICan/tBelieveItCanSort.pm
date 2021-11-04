package Acme::ICan::tBelieveItCanSort {
    use 5.016000;
    use strict;
    use warnings;
    our $VERSION = "0.01";

    package Acme::ICan {

        sub tBelieveItCanSort (@) {
            my @A = @_;
            for my $i ( 0 .. $#A ) {
                for my $j ( 0 .. $#A ) {
                    if ( $A[$i] < $A[$j] ) {
                        @A[ $i, $j ] = @A[ $j, $i ];
                    }
                }
            }
            @A;
        }
    }

=pod

=encoding utf-8

=head1 NAME

Acme::ICan'tBelieveItCanSort - Wait... It Actually Works?

=head1 SYNOPSIS

    use Acme::ICan'tBelieveItCanSort;
        Acme::ICan'tBelieveItCanSort( 3, 4, 5, 5, 68, 1, 4, 321, 32, 321 );

=head1 DESCRIPTION

Acme::ICan'tBelieveItCanSort is a pure Perl implementation of "the simplest
(and most surprising) sorting algorithm ever" as described by Stanley P. Y.
Fung:

    We present an extremely simple sorting algorithm. It may look like it is
    obviously wrong, but we prove that it is in fact correct. We compare it with
    other simple sorting algorithms, and analyse some of its curious properties.

This module itself is named after L<< C<Algorithm
1>|https://arxiv.org/pdf/2110.01111.pdf >>.

=head1 See Also

=over

=item "Is this the simplest (and most surprising) sorting algorithm ever?"

Stanley P. Y. Fung, https://arxiv.org/abs/2110.01111

=item https://github.com/mattn/i_cant_believe_it_can

=item https://github.com/theshteves/simplest-sort

=item https://github.com/PCBoyGames/ArrayV-v4.0/blob/main/src/sorts/exchange/UnbelievableSort.java

=item https://github.com/jefflunt/unbelievable-sort

=back

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

Acme::ICan'tBelieveItCanSort

=end stopwords

=cut

};
1
