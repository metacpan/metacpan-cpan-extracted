#
# AI::ExpertSystem::Advanced::Dictionary
#
# Author(s): Pablo Fischer (pfischer@cpan.org)
# Created: 11/29/2009 20:06:22 CST 20:06:22
package AI::ExpertSystem::Advanced::Dictionary;

=head1 NAME

AI::ExpertSystem::Advanced::Dictionary - Array/hash dictionary

=head1 DESCRIPTION

The dictionary offers a unified interface for:

=over 4

=item 1

Reading through a list of items with a minimal use of memory since it offers an
iterator that works with a stack. So everytime it gets asked for the next
element it I<drops> the first or last element of the stack.

=item 2

Finding an element in the stack.

=item 3

Adding or removing elements from the stack.

=back

=cut
use Moose;
use List::MoreUtils qw(firstidx);

our $VERSION = '0.03';

=head1 Attributes

=over 4

=item B<stack>

An array with all the keys of C<stack_hash>. Useful for creating the
C<iterable_array> and for knowing the order of the items as they get added or
removed.

=cut
has 'stack' => (
        is => 'rw',
        isa => 'ArrayRef');

=item B<stack_hash>

The original hash, has all the elements with all their properties (eg extra
keys). The I<disadvantage> of it is that it doesn't keeps the order of the
elements, hence the need of C<stack>.

=cut
has 'stack_hash' => (
        is => 'ro',
        isa => 'HashRef[Str]');

=item B<iterable_array>

Used by the C<iterate()> and C<iterate_reverse()> methods. It starts as a copy
of C<stack> and as the iterate methods start running this array starts getting
I<reduced> until it gets to an empty list.

=back

=cut
has 'iterable_array' => (
        is => 'ro',
        isa => 'ArrayRef');

=head1 Methods

=head2 B<find($look_for, $find_by)>

Looks for a given value (C<$look_for>). By default it will look for the value
by reading the C<id> of each item, however this can be changed by passing
a different hash key (C<$find_by>).

In case there's no match C<undef> is returned.

=cut
sub find {
    my ($self, $look_for, $find_by) = @_;

    if (!defined($find_by)) {
        if (defined $self->{'stack_hash'}->{$look_for}) {
            return $look_for;
        }
        return undef;
    }

    foreach my $key (keys %{$self->{'stack_hash'}}) {
        if ($self->{'stack_hash'}->{$key}->{$find_by} eq $look_for) {
            return $key;
        }
    }
    return undef;
}

=head2 B<get_value($id, $key)>

The L<AI::ExpertSystem::Advanced::Dictionary> consists of a hash of elements,
each element has its own properties (eg, extra keys).

This method looks for the value of the given C<$key> of a given element C<id>.

It will return the value, but if element doesn't have the given C<$key> then
C<undef> will be returned.

=cut
sub get_value {
    my ($self, $id, $key) = @_;

    if (!defined $self->{'stack_hash'}->{$id}) {
        return undef;
    }
    if (defined $self->{'stack_hash'}->{$id}->{$key}) {
        return $self->{'stack_hash'}->{$id}->{$key};
    } else {
        return undef;
    }
}

=head2 B<append($id, %extra_keys)>

Adds a new element to the C<stack_hash> and C<stack>. The element gets added to
the end of C<stack>.

The C<$id> parameter specifies the id of the new element and the next parameter
is a stack of I<extra> keys.

=cut
sub append {
    my $self = shift;
    my $id = shift;

    return $self->_add($id, undef, @_);
}

=head2 B<prepend($id, %extra_keys)>

Same as C<append()>, but the element gets added to the top of the C<stack>.

=cut
sub prepend {
    my $self = shift;
    my $id = shift;

    return $self->_add($id, 1, @_);
}

=head2 B<update($id, %extra_keys)>

Updates the I<extra> keys of the element that matches the given C<$id>.

Please note that it will only update or add new keys. So if the given element
already has a key and this is not provided in C<%extra_keys> then it wont
be modified.

=cut
sub update {
    my ($self, $id, $properties) = @_;

    if (defined $self->{'stack_hash'}->{$id}) {
        foreach my $key (keys %$properties) {
            $self->{'stack_hash'}->{$id}->{$key} = $properties->{$key};
        }
    } else {
        warn "Not updating $id, does not exist!";
    }
}

=head2 B<remove($id)>

Removes the element that matches the given C<$id> from C<stack_hash> and
C<stack>.

Returns true if the removal is successful, otherwise false is returned.

=cut
sub remove {
    my ($self, $id) = @_;

    if (defined $self->{'stack_hash'}->{$id}) {
        delete($self->{'stack_hash'}->{$id});
        # Find the index in the array, lets suppose our arrays are big
        my $index = List::MoreUtils::first_index {
            defined $_ and $_ eq $id
        } @{$self->{'stack'}};
        splice(@{$self->{'stack'}}, $index, 1);
        return 1;
    }
    return 0;
}

=head2 B<size()>

Returns the size of C<stack>.

=cut
sub size {
    my ($self) = @_;

    return scalar(@{$self->{'stack'}});
}

=head2 B<iterate()>

Returns the first element of the C<iterable_array> and C<iterable_array> is
reduced by one.

If no more items are found in C<iterable_array> then C<undef> is returned.

=cut
sub iterate {
    my ($self) = @_;

    return shift(@{$self->{'iterable_array'}});
}

=head2 B<iterate_reverse()>

Same as C<iterate()>, but instead of returning the first element, it returns
the last element of C<iterable_array>.

=cut
sub iterate_reverse {
    my ($self) = @_;

    return pop(@{$self->{'iterable_array'}});
}

=head2 B<populate_iterable_array()>

The C<iterable_array> gets populated when a dictionary instance is created,
however if new items are added or removed then it's B<extremely> needed to call
this method so C<iterable_array> gets populated again.

=cut
sub populate_iterable_array {
    my ($self) = @_;

    @{$self->{'iterable_array'}} = @{$self->{'stack'}};
}

# No need to document it, used by L<Moose>.
sub BUILD {
    my ($self) = @_;

    foreach (@{$self->{'stack'}}) {
        if (ref($_) eq 'ARRAY') {
            $self->{'stack_hash'}->{$_->[0]} = {
                name => $_->[0],
                sign => $_->[1]
            };
        } else {
            $self->{'stack_hash'}->{$_} = {
                name => $_,
                sign => '+'
            };
        }
    }
    $self->populate_iterable_array();
}

################# Private methods ######################
sub _add {
    my ($self, $id, $prepend, $properties) = @_;
    
    $self->{'stack_hash'}->{$id} = $properties;
    if ($prepend) {
        unshift(@{$self->{'stack'}}, $id);
    } else {
        push(@{$self->{'stack'}}, $id);
    }
}

=head1 AUTHOR
 
Pablo Fischer (pablo@pablo.com.mx).

=head1 COPYRIGHT
 
Copyright (C) 2010 by Pablo Fischer.
 
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
