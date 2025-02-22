package Array::Iterator;

use strict;
use warnings;

=head1 NAME

Array::Iterator - A simple class for iterating over Perl arrays

=head1 VERSION

Version 0.135

=cut

our $VERSION = '0.135';

=head1 SYNOPSIS

C<Array::Iterator> is a Perl module that provides a simple,
uni-directional iterator interface for traversing arrays.
It allows users to iterate over arrays, array references, or hash references containing an array, offering methods like next, has_next, peek, and current to facilitate controlled access to elements.
The iterator maintains an internal pointer, ensuring elements are accessed sequentially without modifying the underlying array.
Tt offers a clean, object-oriented approach to iteration, inspired by Java’s Iterator interface.
The module is extendable, allowing subclassing for custom behaviour.

  use Array::Iterator;

  # create an iterator with an array
  my $i = Array::Iterator->new(1 .. 100);

  # create an iterator with an array reference
  my $i = Array::Iterator->new(\@array);

  # create an iterator with a hash reference
  my $i = Array::Iterator->new({ __array__ => \@array });

  # a base iterator example
  while ($i->has_next()) {
      if ($i->peek() < 50) {
          # ... do something because
          # the next element is over 50
      }
      my $current = $i->next();
      # ... do something with current
  }

  # shortcut style
  my @accumulation;
  push @accumulation => { item => $iterator->next() } while $iterator->has_next();

  # C++ ish style iterator
  for (my $i = Array::Iterator->new(@array); $i->has_next(); $i->next()) {
    my $current = $i->current();
    # .. do something with current
  }

  # common perl iterator idiom
  my $current;
  while ($current = $i->get_next()) {
    # ... do something with $current
  }

It is not recommended to alter the array during iteration, however
no attempt is made to enforce this (although I will if I can find an efficient
means of doing so). This class only intends to provide a clear and simple
means of generic iteration, nothing more (yet).

=head2 new (@array | $array_ref | $hash_ref)

The constructor can be passed either a plain Perl array, an array reference,
or a hash reference (with the array specified as a single key of the hash,
__array__).
Single-element arrays are not supported by either of the first
two calling conventions, since it is not possible to distinguish between an
array of a single-element which happens to be an array reference and an
array reference of a single element, thus previous versions of the constructor
would raise an exception. If you expect to pass arrays to the constructor which
may have only a single element, then the array can be passed as the element
of a HASH reference, with the key, __array__:

  my $i = Array::Iterator->new({ __array__ => \@array });

=cut

sub new {
	my ($_class, @array) = @_;

	(@array) || die 'Insufficient Arguments: you must provide something to iterate over';

	my $class = ref($_class) || $_class;
	my $_array;
	if (scalar @array == 1) {
		if (ref $array[0] eq 'ARRAY') {
		    $_array = $array[0];
		} elsif (ref $array[0] eq 'HASH') {
		    die 'Incorrect type: HASH reference must contain the key __array__'
		        unless exists $array[0]->{__array__};
		    die 'Incorrect type: __array__ value must be an ARRAY reference'
		        unless ref $array[0]->{__array__} eq 'ARRAY';
		    $_array = $array[0]->{__array__};
		}
	}
	else {
		$_array = \@array;
	}
	my $iterator = {
		_current_index => 0,
		_length => 0,
		_iteratee => [],
		_iterated => 0,	# -1 when going backwards, +1 when going forwards
        };
	bless($iterator, $class);
	$iterator->_init(scalar(@{$_array}), $_array);
	return $iterator;
}

sub _init {
	my ($self, $length, $iteratee) = @_;
	(defined($length) && defined($iteratee))
		|| die 'Insufficient Arguments: you must provide an length and an iteratee';
	$self->{_current_index} = 0;
	$self->{_length} = $length;
	# $self->{_iteratee} = $iteratee;

	# Store a private copy to prevent modifications
	$self->{_iteratee} = [@{$iteratee}];
}

=head2 _current_index

An lvalue-ed subroutine that allows access to the iterator's internal pointer.
This can be used in a subclass to access the value.

=cut

# We need to alter this so it's an lvalue
sub _current_index : lvalue {
    (UNIVERSAL::isa((caller)[0], __PACKAGE__))
        || die 'Illegal Operation: This method can only be called by a subclass';
    $_[0]->{_current_index}
}

=head2 _iteratee

This returns the item being iterated over, in our case an array.

=cut

# This we should never need to alter so we don't make it a lvalue
sub _iteratee {
    (UNIVERSAL::isa((caller)[0], __PACKAGE__))
        || die 'Illegal Operation: This method can only be called by a subclass';
    $_[0]->{_iteratee}
}

# we move this from a private method
# to a protected one, and check our access
# as well
sub _getItem {
	(UNIVERSAL::isa((caller)[0], __PACKAGE__)) || die 'Illegal Operation: This method can only be called by a subclass';

	my ($self, $iteratee, $index) = @_;
	return $iteratee->[$index];
}

=head2 _get_item ($iteratee, $index)

This method is used by all other routines to access items. Given the iteratee
and an index, it will return the item being stored in the C<$iteratee> at the index
of C<$index>.

=cut

sub _get_item { my $self = shift; $self->_getItem(@_) }

# we need to alter this so it's an lvalue
sub _iterated : lvalue {
    (UNIVERSAL::isa((caller)[0], __PACKAGE__))
        || die 'Illegal Operation: This method can only be called by a subclass';
    $_[0]->{_iterated}
}

=head2 iterated

Access to the _iterated status, for subclasses

=cut

sub iterated {
    my ($self) = @_;
    return $self->{_iterated};
}

=head2 has_next([$n])

This method returns a boolean. True (1) if there are still more elements in
the iterator, false (0) if there are not.

Takes an optional positive integer (E<gt> 0) that specifies the position you
want to check. This allows you to check if there an element at an arbitrary position.
Think of it as an ordinal number you want to check:

  $i->has_next(2);  # 2nd next element
  $i->has_next(10); # 10th next element

Note that C<has_next(1)> is the same as C<has_next()>.

Throws an exception if C<$n> E<lt>= 0.

=cut

sub has_next {
	my ($self, $n) = @_;

	if(not defined $n) {
		$n = 1
	} elsif(not $n) {
		die "has_next(0) doesn't make sense, did you mean current()?"
	} elsif($n < 0) {
		die "has_next() with negative argument doesn't make sense, perhaps you should use a BiDirectional iterator"
	}

	my $idx = $self->{_current_index} + ($n - 1);

	return ($idx < $self->{_length}) ? 1 : 0;
}

=head2 hasNext

Alternative name for has_next

=cut

sub hasNext { my $self = shift; $self->has_next(@_) }

=head2 next

This method returns the next item in the iterator, be sure to only call this
once per iteration as it will advance the index pointer to the next item. If
this method is called after all elements have been exhausted, an exception
will be thrown.

=cut

sub next {
	my $self = shift;

	($self->{_current_index} < $self->{_length}) || die 'Out Of Bounds: no more elements';

        $self->{_iterated} = 1;
	return $self->_getItem($self->{_iteratee}, $self->{_current_index}++);
}

=head2 get_next

This method returns the next item in the iterator, be sure to only call this
once per iteration as it will advance the index pointer to the next item. If
this method is called after all elements have been exhausted, it will return
undef.

This method was added to allow for a fairly common Perl iterator idiom of:

  my $current;
  while ($current = $i->get_next()) {
      ...
  }

In this,
the loop terminates once C<$current> is assigned to a false value.
The only problem with this idiom for me is that it does not allow for
undefined or false values in the iterator. Of course, if this fits your
data, then there is no problem. Otherwise I would recommend the C<has_next>/C<next>
idiom instead.

=cut

sub get_next {
    my ($self) = @_;
    $self->{_iterated} = 1;
    return undef unless ($self->{_current_index} < $self->{_length}); ## no critic: Subroutines::ProhibitExplicitReturnUndef
    return $self->_getItem($self->{_iteratee}, $self->{_current_index}++);
}

=head2 getNext

Alternative name for get_next

=cut

sub getNext { my $self = shift; $self->get_next(@_) }

=head2 peek([$n])

This method can be used to peek ahead at the next item in the iterator. It
is non-destructive, meaning it does not advance the internal pointer. If
this method is called and attempts to reach beyond the bounds of the iterator,
it will return undef.

Takes an optional positive integer (E<gt> 0) that specifies how far ahead you want to peek:

  $i->peek(2);  # gives you 2nd next element
  $i->peek(10); # gives you 10th next element

Note that C<peek(1)> is the same as C<peek()>.

Throws an exception if C<$n> E<lt>= 0.

B<NOTE:> Before version 0.03 this method would throw an exception if called
out of bounds. I decided this was not a good practice, as it made it difficult
to be able to peek ahead effectively. This is not the case when calling with an argument
that is E<lt>= 0 though, as it's clearly a sign of incorrect usage.

=cut

sub peek {
    my ($self, $n) = @_;

    if(not defined $n) { $n = 1 }
    elsif(not $n)      { die "peek(0) doesn't make sense, did you mean get_next()?" }
    elsif($n < 0)      { die "peek() with negative argument doesn't make sense, perhaps you should use a BiDirectional iterator" }

    my $idx = $self->{_current_index} + ($n - 1);

    return undef unless ($idx < $self->{_length}); ## no critic: Subroutines::ProhibitExplicitReturnUndef
    return $self->_getItem($self->{_iteratee}, $idx);
}

=head2 current

This method can be used to get the current item in the iterator. It is non-destructive,
meaning that it does not advance the internal pointer. This value will match the
last value dispensed by C<next> or C<get_next>.

=cut

sub current {
	my ($self) = @_;
	return $self->_getItem($self->{_iteratee}, $self->currentIndex());
}

=head2 current_index

This method can be used to get the current index in the iterator. It is non-destructive,
meaning that it does not advance the internal pointer. This value will match the index
of the last value dispensed by C<next> or C<get_next>.

=cut

sub current_index {
	my ($self) = @_;
	return ($self->{_current_index} != 0) ? $self->{_current_index} - 1 : 0;
}

=head2 currentIndex

Alternative name for current_index

=cut

sub currentIndex { my $self = shift; $self->current_index(@_) }

=head2 reset

Reset index to allow iteration from the start

=cut

sub reset
{
	my $self = shift;
	$self->{'_current_index'} = 0;
}

=head2 get_length

This is a basic accessor for getting the length of the array being iterated over.

=cut

sub get_length {
	my $self = shift;

	return $self->{_length};
}

=head2 getLength

Alternative name for get_length

=cut

sub getLength { my $self = shift; $self->get_length(@_) }

1;

=head1 TODO

=over 4

=item Improve BiDirectional Test suite

I want to test the back-and-forth a little more and make sure they work well with one another.

=item Other Iterators

Array::Iterator::BiDirectional::Circular, Array::Iterator::Skipable and
Array::Iterator::BiDirectional::Skipable are just a few ideas I have had. I am going
to hold off for now until I am sure they are actually useful.

=back

=head1 SEE ALSO

This module now includes several subclasses of Array::Iterator which add certain behaviors
to Array::Iterator, they are:

=over 4

=item C<Array::Iterator::BiDirectional>

Adds the ability to move backward and forward through the array.

=item C<Array::Iterator::Circular>

When this iterator reaches the end of its list, it will loop back to the start again.

=item C<Array::Iterator::Reusable>

This iterator can be reset to its beginning and used again.

=back

The Design Patterns book by the Gang of Four, specifically the Iterator pattern.

Some of the interface for this class is based on the Java Iterator interface.

=head1 OTHER ITERATOR MODULES

There are several on CPAN with the word Iterator in them.
Most of them are
actually iterators included inside other modules, and only really useful within that
parent module's context. There are, however, some other modules out there that are just
for pure iteration. I have provided a list below of the ones I have found if perhaps
you don't happen to like the way I do it.

=over 4

=item Tie::Array::Iterable

This module ties the array, something we do not do. But it also makes an attempt to
account for, and allow the array to be changed during iteration. It accomplishes this
control because the underlying array is tied. As we all know, tie-ing things can be a
performance issue, but if you need what this module provides, then it will likely be
an acceptable compromise. Array::Iterator makes no attempt to deal with this mid-iteration
manipulation problem.
In fact,
it is recommended to not alter your array with Array::Iterator,
and if possible we will enforce this in later versions.

=item Data::Iter

This module allows for simple iteration over both hashes and arrays.
It does it by
importing several functions that can be used to loop over either type (hash or array)
in the same way. It is an interesting module, it differs from Array::Iterator in
paradigm (Array::Iterator is more OO) and intent.

=item Class::Iterator

This is essentially a wrapper around a closure-based iterator.
This method can be very
flexible, but at times is difficult to manage due to the inherent complexity of using
closures. I actually was a closure-as-iterator fan for a while but eventually moved
away from it in favor of the more plain vanilla means of iteration, like that found
Array::Iterator.

=item Class::Iter

This is part of the Class::Visitor module and is a Visitor and Iterator extension to
Class::Template.
Array::Iterator is a standalone module that is not associated with others.

=item B<Data::Iterator::EasyObj>

Data::Iterator::EasyObj makes your array of arrays into iterator objects.
It also can
further nest additional data structures including Data::Iterator::EasyObj
objects.
Array::Iterator is one-dimensional only and does not attempt to do many of
the more advanced features of this module.

=back

=head1 ACKNOWLEDGEMENTS

=over 4

=item Thanks to Hugo Cornelis for pointing out a bug in C<peek()>

=item Thanks to Phillip Moore for providing the patch to allow single element iteration
through the hash-ref constructor parameter.

=back

=head1 ORIGINAL AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 ORIGINAL COPYRIGHT AND LICENSE

Copyright 2004, 2005 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 PREVIOUS MAINTAINER

Maintained 2017 to 2025 PERLANCAR

=head1 SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to C<bug-array-iterator at rt.cpan.org>,
or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Array-Iterator>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

You can find documentation for this module with the perldoc command.

    perldoc Array::Iterator

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/dist/Array-Iterator>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Array-Iterator>

=item * CPAN Testers' Matrix

L<http://matrix.cpantesters.org/?dist=Array-Iterator>

=item * CPAN Testers Dependencies

L<http://deps.cpantesters.org/?module=Array::Iterator>

=back

=cut
