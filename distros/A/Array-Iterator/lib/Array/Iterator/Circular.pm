
package Array::Iterator::Circular;

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

sub _init {
    my ($self, @args) = @_;
    $self->{loop_counter} = 0;
    $self->SUPER::_init(@args);
}

# always return true, since
# we just keep looping
sub has_next { 1 }

sub next {
	my ($self) = @_;
    unless ($self->_current_index < $self->getLength()) {
        $self->_current_index = 0;
        $self->{loop_counter}++;
    }
        $self->_iterated = 1;
	return $self->_getItem($self->_iteratee(), $self->_current_index++);
}

# since neither of them will
# ever stop dispensing items
# they can just be aliases of
# one another.
*get_next = \&next;

sub is_start {
    my ($self) = @_;
    return ($self->_current_index() == 0);
}

sub isStart { my $self = shift; $self->is_start(@_) }

sub is_end {
    my ($self) = @_;
    return ($self->_current_index() == $self->getLength());
}

sub isEnd { my $self = shift; $self->is_end(@_) }

sub get_loop_count {
    my ($self) = @_;
    return $self->{loop_counter};
}

sub getLoopCount { my $self = shift; $self->get_loop_count(@_) }

1;
#ABSTRACT: A subclass of Array::Iterator to allow circular iteration

=for Pod::Coverage .+

=head1 SYNOPSIS

  use Array::Iterator::Circular;

  # create an instance with a
  # small array
  my $color_iterator = Array::Iterator::Circular->new(qw(red green blue orange));

  # this is a large list of
  # arbitrary items
  my @long_list_of_items = ( ... );

  # as we loop through the items ...
  foreach my $item (@long_list_of_items) {
      # we assign color from our color
      # iterator, which will keep dispensing
      # as it loops through its set
      $item->set_color($color_iterator->next());
  }

  # tell us how many times the set
  # was looped through
  print $color_iterator->get_loop_count();

=head1 DESCRIPTION

This iterator will loop continuosly as long as C<next> or C<get_next> is called. The C<has_next> method will always return true (C<1>), since the list will always loop back. This is useful when you need a list to repeat itself, but don't want to (or care to) know that it is doing so.

=head1 METHODS

This is a subclass of Array::Iterator, only those methods that have been added or altered are documented here, refer to the Array::Iterator documentation for more information.

=over 4

=item B<has_next>

Since we endlessly loop, this will always return true (C<1>).

=item B<next>

This will return the next item in the array, and when it reaches the end of the array, it will loop back to the beginning again.

=item B<get_next>

This method is now defined in terms of C<next>, since neither will even stop dispensing items, there is no need to differentiate.

=item B<is_start>

If at anytime during your looping, you want to know if you have arrived back at the start of you list, you can ask this method.

=item B<is_end>

If at anytime during your looping, you want to know if you have gotten to the end of you list, you can ask this method.

=item B<get_loop_count>

This method will tell you how many times the iterator has looped back to its start.

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
