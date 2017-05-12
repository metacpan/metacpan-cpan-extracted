package Array::Iterator;

use strict;
use warnings;

our $VERSION = '0.11'; # VERSION

### constructor

sub new {
	my ($_class, @array) = @_;
	(@array)
        || die "Insufficient Arguments : you must provide something to iterate over";
	my $class = ref($_class) || $_class;
	my $_array;
	if (scalar @array == 1) {
		if (ref $array[0] eq "ARRAY") {
		    $_array = $array[0];
		}
		elsif (ref $array[0] eq "HASH") {
		    die "Incorrect type : HASH reference must contain the key __array__"
		        unless exists $array[0]->{__array__};
		    die "Incorrect type : __array__ value must be an ARRAY reference"
		        unless ref $array[0]->{__array__} eq 'ARRAY';
		    $_array = $array[0]->{__array__};
		}
		else {
		    die "Incorrect Type : the argument must be an array or hash reference";
		}
	}
	else {
		$_array = \@array;
	}
	my $iterator = {
        _current_index => 0,
        _length => 0,
        _iteratee => [],
        _iterated => 0,
        };
	bless($iterator, $class);
	$iterator->_init(scalar(@{$_array}), $_array);
	return $iterator;
}

### methods

# private methods

sub _init {
	my ($self, $length, $iteratee) = @_;
	(defined($length) && defined($iteratee))
        || die "Insufficient Arguments : you must provide an length and an iteratee";
	$self->{_current_index} = 0;
	$self->{_length} = $length;
	$self->{_iteratee} = $iteratee;
}

# protected method

# this can be used in a subclass to access the value

# we need to alter this so its an lvalue
sub _current_index : lvalue {
    (UNIVERSAL::isa((caller)[0], __PACKAGE__))
        || die "Illegal Operation : This method can only be called by a subclass";
    $_[0]->{_current_index}
}

# this we should never need to alter
# so we dont make it a lvalue
sub _iteratee {
    (UNIVERSAL::isa((caller)[0], __PACKAGE__))
        || die "Illegal Operation : This method can only be called by a subclass";
    $_[0]->{_iteratee}
}

# we move this from a private method
# to a protected one, and check our access
# as well
sub _getItem {
    (UNIVERSAL::isa((caller)[0], __PACKAGE__))
        || die "Illegal Operation : This method can only be called by a subclass";
	my ($self, $iteratee, $index) = @_;
	return $iteratee->[$index];
}

sub _get_item { my $self = shift; $self->_getItem(@_) }

# we need to alter this so its an lvalue
sub _iterated : lvalue {
    (UNIVERSAL::isa((caller)[0], __PACKAGE__))
        || die "Illegal Operation : This method can only be called by a subclass";
    $_[0]->{_iterated}
}

# public methods

# this defines the interface
# an iterator object will have

sub iterated {
    my ($self) = @_;
    return $self->{_iterated};
}

sub has_next {
	my ($self, $n) = @_;

    if(not defined $n) { $n = 1 }
    elsif(not $n)      { die "has_next(0) doesn't make sense, did you mean current()?" }
    elsif($n < 0)      { die "has_next() with negative argument doesn't make sense, perhaps you should use a BiDirectional iterator" }

    my $idx = $self->{_current_index} + ($n - 1);

	return ($idx < $self->{_length}) ? 1 : 0;
}

sub hasNext { my $self = shift; $self->has_next(@_) }

sub next {
	my ($self) = @_;
    ($self->{_current_index} < $self->{_length})
        || die "Out Of Bounds : no more elements";
        $self->{_iterated} = 1;
	return $self->_getItem($self->{_iteratee}, $self->{_current_index}++);
}

sub get_next {
	my ($self) = @_;
        $self->{_iterated} = 1;
    return undef unless ($self->{_current_index} < $self->{_length});
	return $self->_getItem($self->{_iteratee}, $self->{_current_index}++);
}

sub getNext { my $self = shift; $self->get_next(@_) }

sub peek {
	my ($self, $n) = @_;

    if(not defined $n) { $n = 1 }
    elsif(not $n)      { die "peek(0) doesn't make sense, did you mean get_next()?" }
    elsif($n < 0)      { die "peek() with negative argument doesn't make sense, perhaps you should use a BiDirectional iterator" }

    my $idx = $self->{_current_index} + ($n - 1);

    return undef unless ($idx < $self->{_length});
	return $self->_getItem($self->{_iteratee}, $idx);
}

sub current {
	my ($self) = @_;
	return $self->_getItem($self->{_iteratee}, $self->currentIndex());
}

sub current_index {
	my ($self) = @_;
	return ($self->{_current_index} != 0) ? $self->{_current_index} - 1 : 0;
}

sub currentIndex { my $self = shift; $self->current_index(@_) }

sub get_length {
    my ($self) = @_;
    return $self->{_length};
}

sub getLength { my $self = shift; $self->get_length(@_) }

1;
#ABSTRACT: A simple class for iterating over Perl arrays

__END__

=pod

=head1 NAME

Array::Iterator - A simple class for iterating over Perl arrays

=head1 VERSION

version 0.11

=head1 SYNOPSIS

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

=head1 DESCRIPTION

This class provides a very simple iterator interface. It is is uni-directional
and can only be used once. It provides no means of reverseing or reseting the
iterator. It is not recommended to alter the array during iteration, however
no attempt is made to enforce this (although I will if I can find an efficient
means of doing so). This class only intends to provide a clear and simple
means of generic iteration, nothing more (yet).

=for Pod::Coverage .+

=head1 METHODS

=head2 Public Methods

=over 4

=item B<new (@array | $array_ref | $hash_ref)>

The constructor can be passed either a plain perl array, an array reference,
or a hash reference (with the array specified as a single key off the hash,
__array__). Single element arrays are not supported by either of the first
two calling conventions, since it is not possible to distinguish between an
array of a single element which happens to be an array reference, and an
array reference of a single element, thus previous versions of the constructor
would raise an exception. If you expect to pass arrays to the constructor which
may have only a single element, then the array can be passed as the element
of a HASH reference, with the key, __array__:

  my $i = Array::Iterator->new({ __array__ => \@array });

=item B<has_next([$n])>

This methods returns a boolean. True (1) if there are still more elements in
the iterator, false (0) if there are not.

Takes an optional positive integer (E<gt> 0) that specifies the position you
want to check. This allows you to check if there an element at arbitrary position.
Think of it as an ordinal number you want to check:

  $i->has_next(2);  # 2nd next element
  $i->has_next(10); # 10th next element

Note that C<has_next(1)> is the same as C<has_next()>.

Throws an exception if C<$n> E<lt>= 0.

=item B<next>

This method returns the next item in the iterator, be sure to only call this
once per iteration as it will advance the index pointer to the next item. If
this method is called after all elements have been exhausted, an exception
will be thrown.

=item B<get_next>

This method returns the next item in the iterator, be sure to only call this
once per iteration as it will advance the index pointer to the next item. If
this method is called after all elements have been exhausted, it will return
undef.

This method was added to allow for a faily common perl iterator idiom of:

  my $current;
  while ($current = $i->get_next()) {
      ...
  }

In this the loop terminates once C<$current> is assigned to a false value.
The only problem with this idiom for me is that it does not allow for
undefined or false values in the iterator. Of course, if this fits your
data, then there is no problem. Otherwise I would recommend the C<has_next>/C<next>
idiom instead.

=item B<peek([$n])>

This method can be used to peek ahead at the next item in the iterator. It
is non-destructuve, meaning it does not advance the internal pointer. If
this method is called and attempts to reach beyond the bounds of the iterator,
it will return undef.

Takes an optional positive integer (E<gt> 0) that specifies how far ahead you want to peek:

  $i->peek(2);  # gives you 2nd next element
  $i->peek(10); # gives you 10th next element

Note that C<peek(1)> is the same as C<peek()>.

Throws an exception if C<$n> E<lt>= 0.

B<NOTE:> Prior to version 0.03 this method would throw an exception if called
out of bounds. I decided this was not a good practice, as it made it difficult
to be able to peek ahead effectively. This not the case when calling with an argument
that is E<lt>= 0 though, as it's clearly a sign of incorrect usage.

=item B<current>

This method can be used to get the current item in the iterator. It is non-destructive,
meaning that it does not advance the internal pointer. This value will match the
last value dispensed by C<next> or C<get_next>.

=item B<current_index>

This method can be used to get the current index in the iterator. It is non-destructive,
meaning that it does not advance the internal pointer. This value will match the index
of the last value dispensed by C<next> or C<get_next>.

=item B<get_length>

This is a basic accessor for getting the length of the array being iterated over.

=back

=head2 Protected Methods

These methods are I<protected>, in the Java/C++ sense of the word. They can only be
called internally by subclasses of Array::Iterator, an exception is thrown if that
condition is violated. They are documented here only for people interested in
subclassing Array::Iterator.

=over 4

=item B<_current_index>

An lvalue-ed subroutine which allows access to the iterator's internal pointer.

=item B<_iteratee>

This returns the item being iteratated over, in our case an array.

=item B<_get_item ($iteratee, $index)>

This method is used by all other routines to access items with. Given the iteratee
and an index, it will return the item being stored in the C<$iteratee> at the index
of C<$index>.

=back

=head1 TO DO

=over 4

=item Improve BiDirectional Test suite

I want to test the back and forth a little more, make sure they work well with
one another.

=item Other Iterators

Array::Iterator::BiDirectional::Circular, Array::Iterator::Skipable and
Array::Iterator::BiDirectional::Skipable are just a few ideas I have had. I am going
to hold off for now until I am sure they are actually useful.

=back

=head1 BUGS

None that I am aware of. The code is pretty thoroughly tested (see L<CODE COVERAGE> below)
and is based on an (non-publicly released) module which I had used in production systems
for about 2 years without incident. Of course, if you find a bug, let me know, and I will
be sure to fix it.

=head1 CODE COVERAGE

I use B<Devel::Cover> to test the code coverage of my tests, below is the B<Devel::Cover>
report on this module's test suite.

 ------------------------------- ------ ------ ------ ------ ------ ------ ------
 File                              stmt   bran   cond    sub    pod   time  total
 ------------------------------- ------ ------ ------ ------ ------ ------ ------
 Array/Iterator.pm                100.0  100.0   66.7  100.0  100.0   67.6   98.2
 Array/Iterator/BiDirectional.pm  100.0  100.0    n/a  100.0  100.0   20.2  100.0
 Array/Iterator/Circular.pm       100.0  100.0    n/a  100.0  100.0    7.1  100.0
 Array/Iterator/Reusable.pm       100.0    n/a    n/a  100.0  100.0    5.0  100.0
 ------------------------------- ------ ------ ------ ------ ------ ------ ------
 Total                            100.0  100.0   66.7  100.0  100.0  100.0   99.0
 ------------------------------- ------ ------ ------ ------ ------ ------ ------

=head1 SEE ALSO

This module now includes several subclasses of Array::Iterator which add certain behaviors
to Array::Iterator, they are:

=over 4

=item B<Array::Iterator::BiDirectional>

Adds the ability to move backwards and forwards through the array.

=item B<Array::Iterator::Circular>

When this iterator reaches the end of its list, it will loop back to the start again.

=item B<Array::Iterator::Reusable>

This iterator can be reset to its beginning and used again.

=back

The Design Patterns book by the Gang of Four, specifically the Iterator pattern.

Some of the interface for this class is based upon the Java Iterator interface.

=head1 OTHER ITERATOR MODULES

There are a number of modules on CPAN with the word Iterator in them. Most of them are
actually iterators included inside other modules, and only really useful within that
parent modules context. There are however some other modules out there that are just
for pure iteration. I have provided a list below of the ones I have found, if perhaps
you don't happen to like the way I do it.

=over 4

=item B<Tie::Array::Iterable>

This module ties the array, something we do not do. But it also makes an attempt to
account for, and allow the array to be changed during iteration. It accomplishes this
control because the underlying array is tied. As we all know, tie-ing things can be a
performance issue, but if you need what this module provides, then it will likely be
an acceptable compromise. Array::Iterator makes no attempt to deal with this mid-iteration
manipulation problem. In fact it is recommened to not alter your array with Array::Iterator,
and if possible we will enforce this in later versions.

=item B<Data::Iter>

This module allows for simple iteratation over both hashes and arrays. It does it by
importing several functions which can be used to loop over either type (hash or array)
in the same way. It is an interesting module, it differs from Array::Iterator in
paradigm (Array::Iterator is more OO) as well as in intent.

=item B<Class::Iterator>

This is essentially a wrapper around a closure based iterator. This method can be very
flexible, but at times is difficult to manage due to the inherent complextity of using
closures. I actually was a closure-as-iterator fan for a while, but eventually moved
away from it in favor of the more plain vanilla means of iteration, like that found
Array::Iterator.

=item B<Class::Iter>

This is part of the Class::Visitor module, and is a Visitor and Iterator extensions to
Class::Template. Array::Iterator is a standalone module not associated with others.

=item B<Data::Iterator::EasyObj>

Data::Iterator::EasyObj makes your array of arrays into iterator objects. It also has
the ability to further nest additional data structures including Data::Iterator::EasyObj
objects. Array::Iterator is one dimensional only, and does not attempt to do many of
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

=head1 AUTHOR

Steven Haryanto <stevenharyanto@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Steven Haryanto.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
