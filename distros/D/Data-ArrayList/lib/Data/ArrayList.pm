use strict;
use warnings;
package Data::ArrayList;
BEGIN {
  $Data::ArrayList::VERSION = '0.01';
}
# ABSTRACT: java.util.ArrayList for perl

use Moose;
use Data::Clone ();

use Data::ArrayList::ListIterator;


has '_data' => (
    is => 'ro',
    isa => 'ArrayRef[Any]',
    traits => [qw( Array )],
    default => sub { [] },
    handles => {
        '_addAt' => 'splice',
        '_set' => 'set',
        '_get' => 'get',
        '_clear' => 'clear',
        '_delete' => 'delete',
    },
);

has '_size' => (
    is => 'rw',
    isa => 'Int',
    traits => [qw( Counter )],
    default => 0,
    handles => {
        '_inc_size' => 'inc',
        '_dec_size' => 'dec',
        '_reset_size' => 'reset',
    },
);

has '_mod_count' => (
    is => 'rw',
    isa => 'Int',
    traits => [qw( Counter )],
    default => 0,
    handles => {
        '_inc_modcount' => 'inc',
    },
);

around BUILDARGS => sub {
    my $next = shift;
    my $class = shift;

    return $class->$next({ _initialCapacity => @_ || 10 });
};

sub BUILD {
    my ( $self, $params ) = @_;

    # ensureCapacity only on parent objects
    if ( ref $self eq __PACKAGE__ ) {
        $self->ensureCapacity( $params->{_initialCapacity} );
    };

    return $self;
};


sub add {
    my $self = shift;

    die "IllegalArgument"
        unless scalar @_;

    $self->_addAt( $self->_size, 0, @_ );

    $self->_inc_size( scalar @_ );
    $self->_inc_modcount;

    return 1;
}


sub addAt {
    my $self = shift;
    my $index = shift;

    die "IndexOutOfBounds"
        unless $self->_checkIndexForAdd( $index );

    die "IllegalArgument"
        unless scalar @_;

    $self->_addAt( $index, 0, @_ );

    $self->_inc_size( scalar @_ );
    $self->_inc_modcount;

    return 1;
}


sub get {
    my $self = shift;
    my $index = shift;

    die "IndexOutOfBounds"
        unless $self->_checkIndex( $index );

    return $self->_get($index);
}


sub addAll {
    shift->add( @_ );
}


sub addAllAt {
    shift->addAt( @_ );
}


sub clear {
    my $self = shift;

    $self->_clear;
    $self->_reset_size;
    $self->_inc_modcount;
}



sub isEmpty {
    return $_[0]->size == 0;
}


sub indexOf {
    my $self = shift;
    my $comparator = shift;

    for my $i ( 0 .. ($self->size - 1) ) {
        local *_ = \( $self->get($i) );
        return $i if $comparator->();
    }
    return -1;
}


sub lastIndexOf {
    my $self = shift;
    my $comparator = shift;

    for my $i ( reverse 0 .. ($self->size - 1) ) {
        local *_ = \( $self->get($i) );
        return $i if $comparator->();
    }
    return -1;
}


sub contains {
    shift->indexOf(@_) >= 0;
}


sub size {
    return $_[0]->_size;
}


sub clone {
    my $self = shift;

    return bless { %$self }, ref $self;
}


sub toArray {
    return @{ Data::Clone::clone($_[0]->_data) };
}


sub set {
    my $self = shift;
    my $index = shift;

    die "IllegalArgument"
        unless scalar @_;

    my $value = shift;

    die "IndexOutOfBounds"
        unless $self->_checkIndex( $index );

    my $old = $self->get($index);
    $self->_set( $index, $value );

    return $old;
}


sub ensureCapacity {
    my $self = shift;
    my $capacity = shift;

    die "IllegalArgument"
        unless $capacity;

    my $size = $self->size;
    if ( $capacity > $size ) {
        my $d = $self->_data;
        $d->[$capacity] =  undef;
        delete $d->[$capacity];
        return 1;
    };
}


sub remove {
    my $self = shift;

    die "IllegalArgument"
        unless scalar @_;
    my $index = shift;

    die "IndexOutOfBounds"
        unless $self->_checkIndex( $index );

    my $old = $self->get($index);
    $self->_delete( $index );

    $self->_dec_size;
    $self->_inc_modcount;

    return $old;
}

sub _removeRange {
    my $self = shift;
    my $rangeFrom = shift;
    my $rangeTo = shift;


    $self->_addAt( $rangeFrom, $rangeTo - $rangeFrom );

    $self->_dec_size( $rangeTo - $rangeFrom );
    $self->_inc_modcount;

    return 1;
}


sub listIterator {
    my $self = shift;

    my $initialPosition = shift || 0;

    die "IndexOutOfBounds"
        unless $self->_checkIndex( $initialPosition );

    my $iter = Data::ArrayList::ListIterator->new(
        _mod_count => $self->_mod_count,
        _parent => $self,
        _cursor => $initialPosition,
    );

    return $iter;
}


sub subList {
    my $SELF = shift;
    my $rangeFrom = shift;
    my $rangeTo = shift;
    my $offset = shift || 0;

    die "IllegalArgument"
        unless defined $rangeFrom
               && $rangeTo;

    die "IndexOutOfBounds" unless
        $SELF->_checkSubListRange( $rangeFrom, $rangeTo );

    my $sl_meta = Moose::Meta::Class->create_anon_class(
        superclasses => [ $SELF->meta->name ],
    );

    $sl_meta->add_attribute(
        _parentOffset => (
            isa => 'Int',
            default => $rangeFrom,
            is => 'ro',
        )
    );
    $sl_meta->add_attribute(
        _offset => (
            isa => 'Int',
            default => $offset + $rangeFrom,
            is => 'ro',
        )
    );
    $sl_meta->add_attribute(
        _parent => (
            isa => 'Data::ArrayList',
            default => sub { $SELF },
            is => 'rw',
        )
    );
    $sl_meta->add_method('_checkCoMod', Class::MOP::Method->wrap(
            name => '_checkCoMod',
            package_name =>  $sl_meta->name,
            body => sub {
                return $_[0]->_mod_count == $SELF->_mod_count;
            },
        )
    );

    $sl_meta->add_around_method_modifier('set',
        sub {
            shift; # next
            my $self = shift;

            die "IllegalArgument"
                unless scalar @_;

            my $index = shift;

            die "ConcurrentModification" unless
                $self->_checkCoMod;

            die "IndexOutOfBounds"
                unless $self->_checkIndex( $index );

            return $SELF->set( $self->_offset + $index, @_ );
        }
    );
    $sl_meta->add_around_method_modifier('get',
        sub {
            shift; # next
            my $self = shift;
            my $index = shift;

            die "ConcurrentModification" unless
                $self->_checkCoMod;

            die "IndexOutOfBounds"
                unless $self->_checkIndex( $index );

            return $SELF->get( $self->_offset + $index );
        }
    );

    $sl_meta->add_around_method_modifier('size',
        sub {
            my $next = shift;
            my $self = shift;

            die "ConcurrentModification" unless
                $self->_checkCoMod;

            return $self->$next();
        }
    );
    $sl_meta->add_around_method_modifier('add',
        sub {
            shift; # next
            my $self = shift;

            $self->addAt( $self->size, @_ );

            return 1;
        }
    );

    $sl_meta->add_around_method_modifier('addAt',
        sub {
            shift; # next
            my $self = shift;
            my $index = shift;

            die "ConcurrentModification" unless
                $self->_checkCoMod;

            die "IndexOutOfBounds"
                unless $self->_checkIndexForAdd( $index );

            $self->_parent->addAt( $self->_parentOffset + $index, @_ );

            $self->_inc_size( scalar @_ );

            $self->_mod_count( $self->_parent->_mod_count );
        }
    );
    $sl_meta->add_around_method_modifier('remove',
        sub {
            shift; # next
            my $self = shift;

            die "IllegalArgument"
                unless scalar @_;

            my $index = shift;

            die "ConcurrentModification" unless
                $self->_checkCoMod;

            die "IndexOutOfBounds"
                unless $self->_checkIndex( $index );

            my $old = $self->_parent->remove( $self->_parentOffset + $index );

            $self->_dec_size();

            $self->_mod_count( $self->_parent->_mod_count );

            return $old;
        }
    );


    $sl_meta->add_around_method_modifier('clear',
        sub {
            shift; # next
            my $self = shift;

            return $self->_removeRange( 0, $self->size );
        }
    );

    $sl_meta->add_around_method_modifier('_removeRange',
        sub {
            shift; # next
            my $self = shift;
            my $rangeFrom = shift;
            my $rangeTo = shift;

            $self->_parent->_removeRange(
                $self->_parentOffset + $rangeFrom,
                $self->_parentOffset + $rangeTo,
            );

            $self->_mod_count( $self->_parent->_mod_count );
            $self->_dec_size( $rangeTo - $rangeFrom );

            return 1;
        }
    );
    $sl_meta->add_around_method_modifier('toArray',
        sub {
            shift; # next
            my $self = shift;

            die "ConcurrentModification" unless
                $self->_checkCoMod;

            my $d = $SELF->_data;
            return @{ Data::Clone::clone([ @$d[ $self->_offset .. $self->size ]]) };
        }
    );
    $sl_meta->add_around_method_modifier('ensureCapacity',
        sub {
            die "UnsupportedOperationException";
        }
    );
    $sl_meta->add_around_method_modifier('subList',
        sub {
            shift; # next
            my $self = shift;
            my $rangeFrom = shift;
            my $rangeTo = shift;

            die "ConcurrentModification" unless
                $self->_checkCoMod;

            die "IndexOutOfBounds" unless
                $self->_checkSubListRange( $rangeFrom, $rangeTo );

            my $sublist = $SELF->subList($rangeFrom, $rangeTo, $self->_offset);
            $sublist->_parent( $self );

            return $sublist;
        }
    );

    $sl_meta->make_immutable;

    my $sublist = $sl_meta->new_object();

    $sublist->_size($rangeTo - $rangeFrom);
    $sublist->_mod_count($SELF->_mod_count);

    return $sublist;
}

sub _checkIndex {
    my $self = shift;
    my $index = shift;

    return $index < 0 || $index >= $self->size ? 0 : 1;
}

sub _checkIndexForAdd {
    my $self = shift;
    my $index = shift;

    return $index < 0 || $index > $self->size ? 0 : 1;
}

sub _checkSubListRange {
    my $self = shift;
    my $rangeFrom = shift;
    my $rangeTo = shift;

    return $rangeFrom < 0
        || $rangeTo > $self->size
        || $rangeFrom > $rangeTo ? 0 : 1;
}


__PACKAGE__->meta->make_immutable;

1;

__END__
=pod

=encoding utf-8

=head1 NAME

Data::ArrayList - java.util.ArrayList for perl

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    use Data::ArrayList;

    my $dal = Data::ArrayList->new( my $initialCapacity = 20 );

    say "is empty" if $dal->isEmpty;

    $dal->add("at the end");

    $dal->addAll( 1 .. 100 );

    $dal->add("at the end");

    say $dal->get( 12 );
    # prints 12

    $dal->set(12, "I was 12 before");

    say $dal->indexOf(sub { /^at the end$/ });
    # prints 0

    say $dal->lastIndexOf(sub { /^at the end$/ });
    # prints 101

    my $shallowcopy = $dal->clone;

    my @deepcopyofelements = $dal->toArray();

    $dal->ensureCapacity( 1_999_999 );
    $dal->addAll( 1 .. 1_000_000 );

    say $dal->size;
    # prints 1000102

    $dal->remove( 12 );

    say $dal->get( 12 );
    # prints 13

    my $sublist = $dal->subList( 101, 1_000_101 );
    $sublist->clear;

    say $dal->size;
    # prints 101

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

    $dal->clear;

    say $dal->size;
    # prints 0

=head1 DESCRIPTION

Data::ArrayList is a perl port of I<java.util.ArrayList> with some of the methods
inherited from I<java.util.AbstractList>.

Please note that the author strongly encourages users of this module to read
L<perlfunc/"Perl Functions by Category "> I<Functions for real @ARRAYs>,
as use of this module introduces significant performance penalties (non-OO
with native functions is at least twice as fast).

However he believes that chance of converting Java developers to perl is worth
existence of this module.

Besides it was also fun to write ;-)

=head1 METHODS

=head2 add

    $dal->add( $element );

Appends the specified element to the end of this list.

=head2 addAt

    $dal->addAt( $index, $element );

Inserts the specified element at the specified position in this list. Shifts
the element currently at that position (if any) and any subsequent elements
to the right (adds one to their indices).

=head2 get

    my $element = $dal->get( $index );

Returns the element at the specified position in this list.

=head2 addAll

    $dal->addAll( @elements );

Appends all of the specified elements to the end of this list, in their current
order.

=head2 addAllAt

    $dal->addAllAt( $index, @elements );

Inserts all of the specified elements into this list, starting at the specified
position. Shifts the element currently at that position (if any) and any
subsequent elements to the right (increases their indices). The new elements
will appear in the list in their current order.

=head2 clear

    $dal->clear;

Removes all of the elements from this list. The list will be empty after this
call returns.

=head2 isEmpty

    $dal->isEmpty;

Returns I<true> if this list contains no elements.

=head2 indexOf

    my $index = $dal->indexOf( sub { $_ =~ /^value$/ } );

Returns the index of the first occurrence in this list of the element for
which the specified anonymous sub returns true, or -1 if this list does not
contain the element.

=head2 lastIndexOf

    my $index = $dal->lastIndexOf( sub { $_ =~ /^value$/ } );

Returns the index of the last occurrence in this list of the element for
which the specified anonymous sub returns true, or -1 if this list does not
contain the element.

=head2 contains

    $dal->contains( sub { $_ =~ /^value$/ } );

Returns I<true> if the list contains an element for which the specified
anonymous sub returns true.

=head2 size

    my $size_of_list = $dal->size;

Returns the number of elements in this list.

=head2 clone

    my $copy = $dal->clone;

Returns a shallow copy of this instance.
The elements themselves are not copied.

=head2 toArray

    my @elements = $dal->toArray;

Returns an array containing all of the elements in this list in proper
sequence (from first to last element).

The returned array will be "safe" in that no references to it are maintained
by this list. (In other words, this method must allocate a new array). The
caller is thus free to modify the returned array.

B<Note:> The I<safeness> of the copy is provided by L<Data::Clone>. Please make
sure that all blessed objects implement C<clone> to support deep cloning.

=head2 set

    $dal->set( $index, $value );

Replaces the element at the specified position in this list with the specified
element.

Returns the element previously at the specified position.

=head2 ensureCapacity

    $dal->ensureCapacity( $minCapacity );

Increases the capacity of this instance, if necessary, to ensure that it can
hold at least the number of elements specified by the minimum capacity
argument.

B<Note:> This method is not supported by objects returned by L<"subList">.

=head2 remove

    $dal->remove( $index );

Removes the element at the specified position in this list. Shifts any
subsequent elements to the left (subtracts one from their indices).

Returns the element that was removed from the list.

=head2 listIterator

    my $li = $dal->listIterator( $initialPosition );

Returns a list iterator (L<Data::ArrayList::ListIterator>) of the elements in
this list (in proper sequence), starting at the specified position
(I<default is 0>) in this list. The specified index indicates the first element
that would be returned by an initial call to next. An initial call to previous
would return the element with the specified index minus one.

Iterator will die with C<ConcurrentModification> if the parent list has been
I<structurally modified>. Structural modifications are those that change the
size of the list, or otherwise perturb it in such a fashion that iterations in
progress may yield incorrect results.

=head2 subList

    my $sl = $dal->subList( $rangeFrom, $rangeTo );

Returns a view of the portion of this list between the specified C<rangeFrom>,
inclusive, and C<rangeTo>, exclusive. (If C<rangeFrom> and C<rangeTo> are
equal, the returned list is empty.) The returned list is backed by this list,
so non-structural changes in the returned list are reflected in this list, and
vice-versa. The returned list supports all of the optional list operations
supported by this list.

This method eliminates the need for explicit range operations (of the sort that
commonly exist for arrays). Any operation that expects a list can be used as a
range operation by passing a subList view instead of a whole list. For example,
the following idiom removes a range of elements from a list:

    $dal->subList($from, $to)->clear();

Returned sublist is a subclass of L<Data::ArrayList> and supports all of its
methods (except the L<"ensureCapacity">).

Sublists could be nested, as in:

    $dal->subList( 1, 100 )->subList( 20, 20 );

=for Pod::Coverage     BUILD

=head1 SEE ALSO

=over 4

=item *

L<perlfunc>

=item *

L<List::MoreUtils>

=item *

L<Data::Clone>

=item *

L<http://download.oracle.com/javase/6/docs/api/java/util/ArrayList.html>

=back

=head1 AUTHOR

Alex J. G. Burzyński <ajgb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Alex J. G. Burzyński <ajgb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

