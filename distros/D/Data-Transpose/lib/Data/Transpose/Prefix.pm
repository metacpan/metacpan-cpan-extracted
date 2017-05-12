package Data::Transpose::Prefix;

use strict;
use warnings;

=head1 NAME

Data::Transpose::Prefix - prefix subclass for Data::Transpose

=head1 ATTRIBUTES

=head2 prefix

Prefix for field names. Required.

=head1 METHODS

=head2 field

Overrides method from C<Data::Transpose>.

=cut

use Moo;

extends 'Data::Transpose';

use Data::Transpose::Prefix::Field;

has prefix => (
    is => 'ro',
    required => 1,
);

sub field {
    my ($self, $name) = @_;
    my ($object);

    $object = Data::Transpose::Prefix::Field->new(
        name => $name,
        prefix => $self->prefix,
    );

    push @{$self->_fields}, $object;

    return $object;
};

1;
