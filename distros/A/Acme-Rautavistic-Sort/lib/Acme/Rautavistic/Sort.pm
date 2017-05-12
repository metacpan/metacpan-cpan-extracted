package Acme::Rautavistic::Sort;
BEGIN {
  $Acme::Rautavistic::Sort::AUTHORITY = 'cpan:SCHWIGON';
}
# ABSTRACT: Rautavistic sort functions

use warnings;
use strict;
use 5.006;

our $VERSION = '0.02';

use Scalar::Util 'reftype';
require Exporter;

use vars qw(@ISA @EXPORT_OK %EXPORT_TAGS);

@ISA = qw(Exporter);

@EXPORT_OK   = qw(dropsort dropsortx);
%EXPORT_TAGS = (all => [ qw(dropsort dropsortx) ]);

sub dropsort {
        no warnings 'uninitialized';
        my $last;
        map { $_ ge $last ? $last = $_ : () } @_;
}

sub dropsortx(&@)
{
        # magic variables $a and $b
        use vars qw($a $b);
        no strict 'refs';
        no warnings 'uninitialized';
        my $caller = caller;
        local(*{$caller."::a"}) = \my $a;
        local(*{$caller."::b"}) = \my $b;

        my $comparator = shift;
        my $last;
        map {
             $a = $_;
             $b = $last;
             $comparator->() >= 0 ? $last = $_ : ()
            } @_;
}

1; # End of Acme::Rautavistic::Sort

# TODOs / Ideas:
#   Attribute : Rautavistic(dropsort)
#    an Arrays, always keep dropsort sort order, after each change on array

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::Rautavistic::Sort - Rautavistic sort functions

=head1 SYNOPSIS

 use Acme::Rautavistic::Sort ':all';
 #
 # default alphanumeric comparison
 @res = dropsort( qw(3 2 3 1 5) );      # qw(3 3 5)
 @res = dropsort( qw(cc bb dd aa ee) ); # qw(cc dd ee)
 #
 # force numeric comparison (or other comparators)
 @res = dropsortx { $a <=> $b } 1, 11, 2;

=head1 DESCRIPTION

This module provides rautavistic sort functions. For more description
of the functions see below.

=head2 dropsort

From http://www.dangermouse.net/esoteric/dropsort.html:

Dropsort is a fast, one-pass sorting algorithm suitable for many
applications.

Algorithm Description Dropsort is run on an ordered list of numbers by
examining the numbers in sequence, beginning with the second number in
the list. If the number being examined is less than the number before
it, drop it from the list. Otherwise, it is in sorted order, so keep
it. Then move to the next number.

After a single pass of this algorithm, the list will only contain
numbers that are at least as large as the previous number in the
list. In other words, the list will be sorted!  Analysis Dropsort
requires exactly n-1 comparisons to sort a list of length n, making
this an O(n) algorithm, superior to the typical O(n logn) algorithms
commonly used in most applications.

Dropsort is what is known in the computer science field as a lossy
algorithm. It produces a fast result that is correct, but at the cost
of potentially losing some of the input data. Although to those not
versed in the arts of computer science this may seem undesirable,
lossy algorithms are actually a well-accepted part of computing. An
example is the popular JPEG image compression format, which enjoys
widespread use because of its versatility and usefulness. In similar
fashion, dropsort promises to revolutionise the sorting of data in
fields as diverse as commercial finance, government record-keeping,
and space exploration.

=head1 FUNCTIONS

=head2 dropsort

Drop sort an array:

    @SORTED = dropsort @VALUES

Values are compared using string comparison (i.e., C<cmp>). Use
dropsortx to specify alternate comparators.

=head2 dropsortx

Like dropsort but additionally takes a comparator:

    @SORTED = dropsortx { $a <=> $b } @VALUES

Use the magic variables B<$a> and B<$b> for the comparison of two
values.

Please note, that due to the nature of the algorithm, just reversing
$a and $b does not just reverse the result list.

=head1 ACKNOWLEDGEMENTS

Felix Antonius Wilhelm Ostmann (benchmark, optimization and stunt
coordinator)

=head1 MORE INFO

For more information about rautavistic sort and rautavistic in general
see

=over 4

=item * http://www.dangermouse.net/esoteric/dropsort.html

=item * http://www.rautavistik.de (in german)

=back

=head1 AUTHOR

Steffen Schwigon <ss5@renormalist.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Steffen Schwigon.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
