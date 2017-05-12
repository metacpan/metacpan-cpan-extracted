package Box::Calc::Item;
$Box::Calc::Item::VERSION = '1.0200';
use strict;
use warnings;
use Moose;

with 'Box::Calc::Role::Dimensional';


=head1 NAME

Box::Calc::Item - The container class for the items you wish to pack.

=head1 VERSION

version 1.0200

=head1 SYNOPSIS

 my $item = Box::Calc::Item->new(name => 'Apple', x => 3, y => 3.3, z => 4, weight => 5);

=head1 METHODS

=head2 new(params)

Constructor.

=over

=item params

=over

=item x

The width of your item.

=item y

The length of your item.

=item z

The thickness of your item.

=item weight

The weight of your item.

=item name

The name of your item. If you're referring it back to an external system you may wish to use this field to store you item ids instead of item names.

=back

=back


=head2 name

Returns the name of this item.

=cut

has name => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

=head2 describe

Returns all the important details about this item as a hash reference.

=cut

sub describe {
    my $self = shift;
    return {
        name    => $self->name,
        weight  => $self->weight,
        x       => $self->x,
        y       => $self->y,
        z       => $self->z,
    };
}

=head1 ROLES

This class installs L<Box::Calc::Role::Dimensional>.

=cut

no Moose;
__PACKAGE__->meta->make_immutable;
