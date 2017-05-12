package Dancer::Plugin::Nitesi::Routes::Checkout;

use Dancer ':syntax';
use Dancer::Plugin;
use Dancer::Plugin::Nitesi;

=head1 NAME

Dancer::Plugin::Nitesi::Routes::Checkout - Checkout routes for Nitesi Shop Machine

=cut

register_hook 'before_checkout_display';

=head1 FUNCTIONS

=head2 checkout_route

Returns the checkout route based on the passed routes configuration.

=cut

sub checkout_route {
    my $routes_config = shift;

    return sub {
        my %values;

        # add stuff useful for cart display
        $values{cart} = cart->items;
        $values{cart_subtotal} = cart->subtotal;
        $values{cart_total} = cart->total;

        # call before_checkout_display route so template tokens
        # can be injected
        execute_hook('before_checkout_display', \%values);
        template $routes_config->{checkout}->{template}, \%values;
    }
}

1;
