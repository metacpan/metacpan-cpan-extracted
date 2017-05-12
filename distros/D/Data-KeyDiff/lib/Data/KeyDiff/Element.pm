package Data::KeyDiff::Element;

use strict;
use warnings;

use Object::Tiny qw/key value rank position item in_before in_after is_new/;

=head1 DESCRIPTION 

An element from a set

=head1 METHODS

=head2 $element->key

The key of the item

=head2 $element->value

The prepared value of the item, if a prepare method was given (otherwise, this is just the original item)

=head2 $element->rank

The rank of the item in the set

=head2 $element->position

The position of the item in the set

=head2 $element->item

The original, unmodified item from the set

=head2 $element->in_before

Indicates that the item is from the before set

=head2 $element->in_after

Indicates that the item is from the after set

=head2 $element->is_new

Indicates that the item is new

=cut

1;
