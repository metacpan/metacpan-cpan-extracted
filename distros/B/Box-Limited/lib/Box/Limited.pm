package Box::Limited;

=head1 NAME

Box::Limited - Box with a limited capacity.

=head1 DESCRIPTION

This class represents a box which can contain only a limited number of items
with a limited total weight.
This can be useful e.g. to form requests to a certain API which has
a limit on the number of items / total characters sent within one request.

=head1 SYNOPSIS

    use Box::Limited;
    use List::Util qw(sum0);

    my $box = Box::Limited->new(
        size            => 100,
        max_weight      => 200,
        weight_function => sub (@items) {

            # "Weight" of item is a length of its string form in this case
            return sum0 map { length($_) } @items;
        },
    );

    while (my $item = shift @items) {
        if ($box->can_add($item)) {
            $box->add($item);
        } else {
            say "Box is full";

            # ...process full box...

        }
    }

=cut

use Moo;
use experimental qw(signatures);
use Carp qw(croak);
use Types::Common::Numeric qw(PositiveOrZeroInt);
use Types::Standard qw(CodeRef ArrayRef);

our $VERSION = '0.01';

=head1 ATTRIBUTES

=head3 size

Box size - the maximum amount of items the box can hold. Non-negative integer;
required.

=cut

has size => (
    is       => 'ro',
    isa      => PositiveOrZeroInt,
    required => 1,
);

=head3 max_weight

Maximum weight of all items in the box. Non-negative integer; required.

=cut

has max_weight => (
    is       => 'ro',
    isa      => PositiveOrZeroInt,
    required => 1,
);

=head3 weight_function

Code reference of weighting function; required. Its argument is an array of
items, and return value must be an integer representing weight of all items.

=cut

has weight_function => (
    is       => 'ro',
    isa      => CodeRef,
    required => 1,
);

has _items_ref => (
    is      => 'rw',
    isa     => ArrayRef,
    default => sub { [] },
);

=head1 METHODS

=head3 can_add($item)

Whether C<$item> can be added to the box. C<$item> is any scalar that can be
weighted by C<weight_function>.

=cut

sub can_add ($self, $item) {
    return $self->items_count < $self->size
      && $self->_get_weight_with($item) <= $self->max_weight;

}

sub _get_weight_with ($self, $item) {
    return $self->weight_function->($self->items, $item);
}

=head3 add($item)

Adds C<$item> to the box and returns true. If item cannot be added, raises
exception.

=cut

sub add ($self, $item) {
    if (!$self->can_add($item)) {
        croak "Cannot add item: $item";
    }
    push @{ $self->_items_ref }, $item;
    return 1;
}

=head3 items

Returns array of items in the box in the same order they were added there.

=cut

sub items ($self) {
    return @{ $self->_items_ref };
}

=head3 items_count

Returns number of items in the box.

=cut

sub items_count ($self) {
    return scalar @{ $self->_items_ref };
}

=head3 is_empty

Whether the box is empty or not.

=cut

sub is_empty ($self) {
    return $self->items_count == 0;
}

=head3 clear

Clears the box and returns true.

=cut

sub clear ($self) {
    $self->_items_ref([]);
    return 1;
}

=head3 split_to_boxes(\%constructor_arg, @items)

    In: \%constructor_arg - constructor arguments (all the attributes required
        for new())
    Out: @filled_boxes - array of boxes filled with @items

Class method. Creates as many boxes as required to put all the C<@items> in
them, puts items there and returns boxes.

Items are processed in the order they were passed - there is no heuristic to
minimize the total number of used boxes.

=cut

sub split_to_boxes ($class, $constructor_arg, @items) {
    my @filled_boxes;
    BOX: {
        my $box = $class->new($constructor_arg);
        while (@items) {
            my $item = $items[0];
            if ($box->can_add($item)) {
                $box->add($item);
                shift @items;
            }
            else {
                if ($box->is_empty) {
                    croak "Item is too big to add to the box even alone: $item";
                }
                push @filled_boxes, $box;
                redo BOX;
            }
        }
        push @filled_boxes, $box if !$box->is_empty;
    }
    return @filled_boxes;
}

=head1 AUTHOR

Ilya Chesnokov L<chesnokov@cpan.org>.

=head1 LICENSE

Under the same terms as Perl itself.

=head1 CREDITS

Thanks to L<Perceptyx, Inc|https://perceptyx.com> for sponsoring work on this
module.

=cut

1;
