#
# Copyright (C) 1997 Ken MacLeod
# Class::Iter is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# $Id: Iter.pm,v 1.1.1.1 1997/10/18 16:20:00 ken Exp $
#

package Class::Iter;

use strict;

#
#  Internally, a Class::Iter is an array,
#
#    [0] -- delegate
#    [1] -- parent iterator
#    [2] -- parent's array
#    [3] -- current index
#
#  

sub parent {
    # $self->{parent}
    return $_[0]->[1];
}

sub is_iter {
    return 1;
}

sub root {
    return $_[0]
	if !defined $_[0]->[1];

    # $self->{parent}->root;
    return $_[0]->[1]->root;
}

sub rootpath {
    if (defined $_[0]->[1]) {
	return ($_[0]->[1]->rootpath, $_[0]);
    } else {
	return ($_[0]);
    }
}

# return a new proxy for the next object
sub next {
    my @self = @$_[0];

    return $_[0]
	if ($self[3] == $#{$self[2]});

    shift (@self);
    return $self[1][$self[2] + 1]->iter (@self);
}

sub at_end {
    return $_[3] == $#{$_[2]};
}

# returns what I'm pretending to be
sub delegate {
    return $_[0]->[0];
}

# `is_same' returns true if the two iterators are pointing to the same
# object or if our delegate *is* the object
sub is_same {
    my $self = shift;
    my $obj = shift;

    return ($self->[0] == $obj
	    || (ref ($self) eq ref ($obj)
		&& $self->[0] == $obj->[0]));
}

package Class::Scalar::Iter;
@Class::Scalar::Iter::ISA = qw{Class::Iter};

1;
__END__

=head1 NAME

Class::Iter - Iterator superclass for Class::Visitor

=head1 SYNOPSIS

  use Class::Visitor;

  visitor_class 'CLASS', 'SUPER', { TEMPLATE };
  visitor_class 'CLASS', 'SUPER', [ TEMPLATE ];

  $obj = CLASS->new ();
  $iter = $obj->iter;
  $iter = $obj->iter ($parent, $array, $index);

  $iter->parent;
  $iter->is_iter;
  $iter->root;
  $iter->rootpath;
  $iter->next;
  $iter->at_end;
  $iter->delegate;
  $iter->is_same ($obj);

=head1 DESCRIPTION

C<Class::Iter> defines the majority of iterator methods for iterator
classes created by C<Class::Visitor>.

C<parent> returns the parent of this iterator, or C<undef> if this is
the root object.

C<is_iter> returns true indicating that this object is an iterator
(all other C<is_I<TYPE>> queries would be passed on to the delegate).

C<root> returns the root parent of this iterator.

C<rootpath> returns an array of all iterators between and including
the root and this iterator.

C<next> returns the iterator of the object after this object in the
parent's element.  If there is no next object, C<next> returns
C<$self>.

C<at_end> returns true if this is the last object in the parent's
element, i.e. it returns true if C<next> would return C<$self>.

C<delegate> returns the object that this iterator stands-in for.

C<is_same> returns true if C<$obj> is the delegate or if C<$obj> is an
iterator pointing to the same object.

=head1 AUTHOR

Ken MacLeod, ken@bitsko.slc.ut.us

=head1 SEE ALSO

perl(1), Class::Visitor(3).

=cut
