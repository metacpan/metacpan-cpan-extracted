use utf8;

package Dancer2::Plugin::Interchange6::Cart::Product;

=head1 NAME

Dancer2::Plugin::Interchange6::Cart::Product

=head1 DESCRIPTION

Extends L<Interchange6::Cart::Product>.

=cut

use Interchange6::Types -types;

use Moo;
use MooseX::CoverableModifiers;
extends 'Interchange6::Cart::Product';
use namespace::clean;

=head1 ATTRIBUTES

See L<Interchange6::Cart::Product/ATTRIBUTES> for inherited attributes.

=head2 dbic_product

Used to stash the related L<Interchange6::Schema::Result::Product> object
so that other accessors can be lazily built from it on demand.

Required.

=cut

has dbic_product => (
    is       => 'lazy',
    required => 1,
);

=head2 selling_price

Inherited. Lazily set via L</dbic_product>.

=over

=item clearer: clear_selling_price

=back

L</clear_selling_price> is called whenever
L<Interchange6::Cart::Product/set_quantity> gets called so that possible 
quantity based pricing is recalculated.

=cut

has '+selling_price' => (
    is      => 'lazy',
    clearer => 1,
);

sub _build_selling_price {
    my $self = shift;
    $self->dbic_product->selling_price({quantity => $self->quantity});
}

after 'set_quantity' => sub {
    shift->clear_selling_price;
};

1;
