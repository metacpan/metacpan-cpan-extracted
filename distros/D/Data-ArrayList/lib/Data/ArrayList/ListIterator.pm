use strict;
use warnings;
package Data::ArrayList::ListIterator;
BEGIN {
  $Data::ArrayList::ListIterator::VERSION = '0.01';
}
# ABSTRACT: iterator for Data::ArrayList

use Moose;




has '_parent' => (
    is => 'rw',
    isa => 'Object',
);

has '_cursor' => (
    is => 'rw',
    isa => 'Int',
    traits => [qw( Counter )],
    default => 0,
    handles => {
        '_cursor_next' => 'inc',
        '_cursor_prev' => 'dec',
    },
);

has '_mod_count' => (
    is => 'rw',
    isa => 'Int',
    required => 1,
);

has '_last_ret' => (
    is => 'rw',
    isa => 'Int',
    default => -1,
);


sub hasNext {
    my $self = shift;

    return $self->_cursor < $self->_parent->size;
}


sub hasPrevious {
    return $_[0]->_cursor > 0;
}


sub nextIndex {
    my $self = shift;

    return $self->hasNext ?
        $self->_cursor
            :
        $self->_parent->size;
}


sub previousIndex {
    my $self = shift;

    return $self->_cursor ?  $self->_cursor - 1 : -1;
}


sub next {
    my $self = shift;

    die "NoSuchElement"
        unless $self->hasNext;

    die "ConcurrentModification"
        unless $self->_checkCoMod;

    $self->_last_ret( $self->_cursor );

    my $i = $self->_cursor;
    $self->_cursor_next;

    return $self->_parent->get( $i );
}


sub previous {
    my $self = shift;

    die "NoSuchElement"
        unless $self->hasPrevious;

    die "ConcurrentModification"
        unless $self->_checkCoMod;

    $self->_cursor_prev;
    $self->_last_ret( $self->_cursor );

    return $self->_parent->get( $self->_cursor );
}


sub remove {
    my $self = shift;

    die "ConcurrentModification"
        unless $self->_checkCoMod;

    die "IllegalState"
        if $self->_last_ret < 0;

    $self->_parent->remove( $self->_last_ret );
    $self->_cursor( $self->_last_ret );

    $self->_mod_count( $self->_parent->_mod_count );

    $self->_last_ret( -1 );

    return 1;
}


sub set {
    my $self = shift;

    die "ConcurrentModification"
        unless $self->_checkCoMod;

    die "IllegalState"
        if $self->_last_ret < 0;

    $self->_parent->set( $self->_last_ret, @_ );

    return 1;
}



sub add {
    my $self = shift;

    die "IllegalArgument"
        unless scalar @_;

    die "ConcurrentModification"
        unless $self->_checkCoMod;

    $self->_parent->addAt( $self->_cursor, @_ );

    $self->_cursor_next;

    $self->_mod_count( $self->_parent->_mod_count );

    $self->_last_ret( -1 );

    return;
}

sub _checkCoMod {
    my $self = shift;

    return $self->_mod_count == $self->_parent->_mod_count;
}

__PACKAGE__->meta->make_immutable;

1;

__END__
=pod

=encoding utf-8

=head1 NAME

Data::ArrayList::ListIterator - iterator for Data::ArrayList

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    use Data::ArrayList;

    my $dal = Data::ArrayList->new();

    $dal->addAll( 1 .. 100 );

    my $iter = $dal->listIterator();

    while ( $iter->hasNext ) {
        my $idx = $iter->nextIndex;
        my $elem = $iter->next;

        $iter->add( "$elem from $idx again" );
    }

    while ( $iter->hasPrevious ) {
        my $idx = $iter->previousIndex;

        my $elem = $iter->previous;

        $iter->remove if $elem =~ / again$/;
    }

=head1 DESCRIPTION

Data::ArrayList::ListIterator provides iterator for L<Data::ArrayList>.

=head1 METHODS

=head2 hasNext

    while ( $it->hasNext() ) {
        say $it->next;
    }

Returns I<true> if this list iterator has more elements when traversing the
list in the forward direction.

=head2 hasPrevious

    while ( $it->hasPrevious() ) {
        say $it->previous;
    }

Returns I<true> if this list iterator has more elements when traversing the
list in the reverse direction.

=head2 nextIndex

    while ( $it->hasNext() ) {
        my $index = $it->nextIndex();

        $dal->get($index) == $it->next;
    }

Returns the index of the element that would be returned by a subsequent call
to L<"next">.

Returns list size if the list iterator is at the end of the list.

=head2 previousIndex

    while ( $it->hasPrevious() ) {
        my $index = $it->previousIndex();

        $dal->get($index) == $it->previous;
    }

Returns the index of the element that would be returned by a subsequent call
to L<"previous">.

Returns -1 if the list iterator is at the beginning of the list.

=head2 next

    while ( $it->hasNext() ) {
        say $it->next;
    }

Returns the next element in the list. This method may be called repeatedly to
iterate through the list, or intermixed with calls to L<"previous"> to go back
and forth.

B<Note:> alternating calls to L<"next"> and L<"previous"> will return the same
element repeatedly.

=head2 previous

    while ( $it->hasPrevious() ) {
        say $it->previous;
    }

Returns the previous element in the list. This method may be called repeatedly to
iterate through the list, or intermixed with calls to L<"next"> to go back
and forth.

B<Note:> alternating calls to L<"next"> and L<"previous"> will return the same
element repeatedly.

=head2 remove

    while ( $it->hasNext() ) {
        say $it->next;

        $it->remove;
    }

Removes from the list the last element that was returned by L<"next"> or
L<"previous">.

This call can only be made once per call to L<"next"> or L<"previous">. It can
be made only if L<"add"> has not been called after the last call to L<"next">
or L<"previous">.

=head2 set

    while ( $it->hasNext() ) {
        $it->set( encrypt($it->next) );
    }

Replaces the last element returned by L<"next"> or L<"previous"> with the
specified element.

This call can be made only if neither L<"remove"> nor L<"add"> have been called
after the last call to L<"next"> or L<"previous">.

=head2 add

    while ( $it->hasNext() ) {
        $it->add( $it->next ); # duplicate all elements
    }

Inserts the specified element into the list. The element is inserted
immediately before the next element that would be returned by L<"next">, if
any, and after the next element that would be returned by L<"previous">, if
any.

If the list contains no elements, the new element becomes the sole
element on the list.

The new element is inserted before the implicit cursor: a subsequent call to
L<"next"> would be unaffected, and a subsequent call to L<"previous"> would
return the new element.

This call increases by one the value that would be returned by a
call to L<"nextIndex"> or L<"previousIndex">.

=head1 SEE ALSO

=over 4

=item *

L<Data::ArrayList>

=back

=head1 AUTHOR

Alex J. G. Burzyński <ajgb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alex J. G. Burzyński <ajgb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

