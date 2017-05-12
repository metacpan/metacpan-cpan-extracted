package Data::CircularList::Cell;

use 5.006;
use strict;
use warnings FATAL => 'all';
use parent qw/Class::Accessor/;
__PACKAGE__->mk_accessors(qw/next data/);
use Scalar::Util qw/blessed looks_like_number/;
use Carp;

=head1 NAME

Data::CircularList::Cell - a Cell of the CircularList.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

You can see Data::CircularList module's SYNOPSIS as a example.

=head1 SUBROUTINES/METHODS

=head2 new

constructor. reguire one argument (not necessary) as data.

=cut

sub new {
    my $class = shift;
    my $next = undef;
    my $data = shift;
    bless { next => $next, data => $data }, $class;
}

=head2 data

accessor for data.
data method is readble and writable as below.
thid method is provided by Class::Accessor.

    $self->data;  # read
    $self->data('some data') # write

=cut

=head2 next

accessor for next cell of the CircularList.
next method is readble and writable as below.
thid method is provided by Class::Accessor.

    $self->next;  # read
    $self->next($next_cell) # write

a user doesn't usually use this method directly.

=cut

=head2 compare_to

This method compares to value of self and it by argument.
If self value is big, this method return 1 and if it isn't so return 0.
Each cell is lined in the sorted state at the value in Data::CircularList. it's used for the sorting.
You can use any data as value of cell.
If scalar data you use, this method compares like dictionary.
If object data you use, you have to make orignal class and implement compare_to method.

=cut

sub compare_to {
    my $self = shift;
    my $cell = shift;

    # some object case
    if (blessed($self->data)) {
        # you have to implement compare_to method in your obj
        if (!$cell->can('compare_to')) {
            croak "You have to implement compare_to method in your object(" . ref($cell) . ").\n";
        }
        return $cell->compare_to($self->data) > 0 ? 1 : 0;
    }

    if (looks_like_number($self->data) && looks_like_number($cell->data)) {
        # number case
        return $self->data > $cell->data ? 1 : 0;
    } else {
        # string case
        return $self->data gt $cell->data ? 1 : 0;
    }

    # other case (havn't implemented)
    return 1;
}

=head1 AUTHOR

shinchit, C<< <shinchi.xx at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-datastructure-circularlist at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-CircularList>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::CircularList::Cell


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-CircularList>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-CircularList>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-CircularList>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-CircularList/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 shinchit.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Data::CircularList::Cell
