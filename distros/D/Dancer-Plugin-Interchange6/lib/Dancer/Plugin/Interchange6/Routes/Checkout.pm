package Dancer::Plugin::Interchange6::Routes::Checkout;

use Dancer ':syntax';
use Dancer::Plugin;
use Dancer::Plugin::Interchange6;

=head1 NAME

Dancer::Plugin::Interchange6::Routes::Checkout - Checkout routes for Interchange6 Shop Machine

=cut

register_hook 'before_checkout_display';

=head1 DESCRIPTION

This route isn't active by default and B<not recommended>.

=head1 FUNCTIONS

=head2 checkout_route

Returns the checkout route based on the passed routes configuration.

=cut

sub checkout_route {
    my $routes_config = shift;

    return sub {
        my %values;

        # add stuff useful for cart display
        my $cart = cart;
        $values{cart_subtotal} = $cart->subtotal;
        $values{cart_total} = $cart->total;
        $values{cart} = $cart->products;

        # call before_checkout_display route so template tokens
        # can be injected
        execute_hook('before_checkout_display', \%values);
        template $routes_config->{checkout}->{template}, \%values;
    }
}

1;
