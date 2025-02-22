
package Array::Iterator::Reusable;

use strict;
use warnings;

use Array::Iterator;

# AUTHORITY
# DATE
# DIST

=head1 VERSION

Version 0.135

=cut

our $VERSION = '0.135';

our @ISA = qw(Array::Iterator);

sub reset {
    my ($self) = @_;
    $self->_iterated = 0;
    $self->_current_index = 0;
}

1;
#ABSTRACT: A subclass of Array::Iterator to allow reuse of iterators

=for Pod::Coverage .+

=head1 SYNOPSIS

  use Array::Iterator::Reusable;

  # create an iterator with an array
  my $i = Array::Iterator::Reusable->new(1 .. 100);

  # do something with the iterator
  my @accumulation;
  push @accumulation => { item => $iterator->next() } while $iterator->has_next();

  # now reset the iterator so we can do it again
  $iterator->reset();

=head1 DESCRIPTION

Sometimes you don't want to have to throw out your iterator each time you have exhausted it. This class adds the C<reset> method to allow reuse of an iterator. This is a very simple addition to the Array::Iterator class of a single method.

=head1 METHODS

This is a subclass of Array::Iterator, only those methods that have been added are documented here, refer to the Array::Iterator documentation for more information.

=over 4

=item B<reset>

This resets the internal counter of the iterator back to the start of the array.

=back

=head1 SEE ALSO

This is a subclass of B<Array::Iterator>, please refer to it for more documentation.

=head1 ORIGINAL AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 ORIGINAL COPYRIGHT AND LICENSE

Copyright 2004 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
