package Acme::Sort::Bozo;

use 5.010;

use strict;
use warnings;

use parent qw/Exporter/;
use Carp 'croak';

use List::Util qw/shuffle/;

our @EXPORT = qw/bozo/;

our $VERSION = '0.05';



#   bozo()
#   Usage:
#   Sort a list in standard string comparison order.
#
#   my @sorted = bozo( @unsorted );
#
#   Sort a list in ascending numerical order:
#   sub compare { return $_[0] <=> $_[1] };
#   my @sorted = bozo( \&compare, @unsorted );
#
#   Warning: Average case is O( n! ).
#   Warning: Worst case could approach O(INF).
#
#   bozo() is exported automatically upon use.

sub bozo {
    my $compare = ref( $_[0] ) =~ /CODE/ 
        ?   shift
        :   \&compare;
    return @_ if @_ < 2;
    my $listref = [ @_ ]; # Get a ref to a copy of @_.
    $listref = swap( $listref ) while not is_ordered( $compare, $listref );
    return @{ $listref };
}



# Internal use, not exported.  Verifies order based on $compare->().
sub is_ordered {
    my ( $compare, $listref ) = @_;
    ref( $compare ) =~ /CODE/ 
        or croak "is_ordered() expects a coderef as first arg.";
    ref( $listref ) =~ /ARRAY/
        or croak "is_ordered() expects an arrayref as second arg.";
    foreach( 0 .. $#{$listref} - 1 ) {
        return 0 
            if $compare->( $listref->[ $_ ], $listref->[ $_ + 1 ] ) > 0;
    }
    return 1;
}

# Internal use, not exported.  Simply swaps two random elements.  The elements
# are guaranteed to be distinct.
sub swap {
    my $listref = shift;
    my $elements = @{$listref};
    my $first = int( rand( $elements ) );
    my $second;
    do{ $second = int( rand( $elements ) ); } until $second != $first;
#    ( $listref->[$first], $listref->[$second] ) = ( $listref->[$second], $listref->[$first] );
    @{$listref}[$first, $second] = @{$listref}[$second, $first];
    return $listref;
}


# Default compare() is ascending standard string comparison order.
sub compare {
    croak "compare() requires two args."
        unless scalar @_ == 2;
    return $_[0] cmp $_[1];
}


=head1 NAME

Acme::Sort::Bozo - Implementation of a Bozo sort algorithm.

=head1 VERSION

Version 0.05

=head1 SYNOPSIS

The Bozo is a sort that is based on a "swap and test" paradigm.  It works by 
first testing whether the input is in sorted order.  If so, return the list.  But if not, 
randomly select two elements from the list, swap them, and test again.  Repeat until 
the shuffle comes back sorted.

    use Acme::Sort::Bozo;

    my @unsorted = qw/ E B A C D /;
    my @ascending = bozo( @unsorted );
    
    my @descending = bozo(
        sub{ return $_[1] cmp $_[0]; },
        @unsorted
    );

The worst case for Bozo is difficult to determine, though one study suggests it probably approaches O(INF).
The good news is that, as time (and computation) approaches infinity the odds of not finding a solution decline 
toward zero (assuming a good random number generator).  So if you have an eternity to wait, you'll get your 
results soon enough.  The average case is O( n * n! ).  However, there is no 
guarantee that any particular sort will come in anywhere near average.  Where the bogosort is a 'stateless'
sort, the bozo sort maintains a list state from one iteration to the next, but its decision mechanism for swaps I<is>
stateless; it blindly swaps any random two elements.

Keep in mind that a list of five items consumes an average of 5 * 5!, or 600 iterations.  10! is 
36,288,000 iterations on average.  The universe will either collapse or expand to the point that it cannot sustain
life long before the Bozo sort manages to sort a deck of cards, in the average case.  In the worst case, all of the
background radiation from our universe will have decayed to the point that there is no longer any trace of our 
existence before this sort manages to alphabetically sort your social networking friends list.

Test with short (4 to 7 element) lists, and be prepared to kill the process if you mistakenly hand it more elements
than that.

=head1 EXPORT

Always exports one function: C<bozo()>.

=head1 SUBROUTINES/METHODS

=head2 bozo( @unsorted )

Accepts a list as a parameter and returns a sorted list.

If the first parameter is a reference to a subroutine, it will be used as the
comparison function.

The Bozo is probably mostly useful as a teaching example of a "perversely awful"  sort 
algorithm.  There are approximately 1e80 atoms in the universe.  A sort list of 
59 elements will gain an average case solution of 5.9e81 iterations, with a worst 
case approaching infinite iterations to find a solution.  Anything beyond just a 
few items takes a considerable amount of work.

Each iteration checks first to see if the list is in order.  Here a comparatively 
minor optimization is that the first out-of-order element will short-circuit the 
check.  That step has a worst case of O(n), and average case of nearly O(1).  
That's the only good news.  Once it is determined that the list is out 
of order, a pair of elements (not necessarily adjacent) are chosen at random, and swapped.
Then the test happens all over again, repeating until a solution is happened across by chance.

There is a potential for this sort to never finish, since a typical random number
synthesizer does not generate an infinitely non-repeating series.  Because this 
algorithm has the capability of producing O(INF) iterations, it would need an 
infinite source of random numbers to find a solution in any given dataset.  

Small datasets are unlikely to encounter this problem, but as the dataset grows, 
so does the propensity for running through the entire set of pseudo-random numbers 
generated by Perl's rand() for a given seed.  None of this really matters, of course, 
as no sane individual would ever use this for any serious sorting work.

Do you feel lucky today, chump?


=cut


=head2 compare( $a, $b )

By passing a subref as the first parameter to C<bozo()>, the user is able to 
manipulate sort orders just as is done with Perl's built in C< sort { code } @list > 
routine.

The comparison function is easy to implement using Perl's C<< <=> >> and C< cmp > 
operators, but any amount of creativity is ok so long as return values are negative 
for "Order is ok", positive for "Order is not ok", and 0 for "Terms are equal 
(Order is ok)".

=cut


=head1 AUTHOR

David Oswald, C<< <davido[at]cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-acme-sort-bozo at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Acme-Sort-Bozo>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::Sort::Bozo


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-Sort-Bozo>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Acme-Sort-Bozo>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Acme-Sort-Bozo>

=item * Search CPAN

L<http://search.cpan.org/dist/Acme-Sort-Bozo/>

=back


=head1 SEE ALSO

=over 4

=item * The Bogosort (test and shuffle) - Another I<Perversely Awful> sorting algorithm.

L<http://search.cpan.org/perldoc?Acme::Sort::Bogosort>

=back


=head1 ACKNOWLEDGEMENTS

=over 4

=item * Wikipedia article on the Bogosort and Bozo sort

L<http://en.wikipedia.org/wiki/Bogosort> 

=item * Sorting the Slow Way: An analysis of Perversely Awful Randomized Sorting Algorithms

L<http://www.hermann-gruber.com/data/fun07-final.pdf> 

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2011 David Oswald.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Acme::Sort::Bozo
