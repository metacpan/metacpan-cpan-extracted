
package Continuity::Meta::Attribute::FormField;
use Moose;
extends 'Moose::Meta::Attribute';

has label => (
    is  => 'rw',
    isa => 'Str',
    predicate => 'has_label',
);

package Moose::Meta::Attribute::Custom::FormField;
sub register_implementation { 'Continuity::Meta::Attribute::FormField' }

1;

