package Dancer::Plugin::Nitesi::Routes::Cart;

use Dancer ':syntax';
use Dancer::Plugin;
use Dancer::Plugin::Nitesi;

=head1 NAME

Dancer::Plugin::Nitesi::Routes::Cart - Cart routes for Nitesi Shop Machine

=cut

register_hook 'before_cart_display';

=head1 FUNCTIONS

=head2 cart_route

Returns the cart route based on the passed routes configuration.

=cut

sub cart_route {
    my $routes_config = shift;

    return sub {
        my %values;
        my ($input, $product, $cart_item, $cart_name, $cart_input);

        if ($input = param('sku')) {
            if (scalar($input)) {
                $product = shop_product($input);
                $product->load;

                $cart_input = {sku => $product->sku,
                               name => $product->name,
                               price => $product->price};

                if ($cart_name = param('cart')
                    && scalar($cart_name)) {
                    $cart_item = cart($cart_name)->add($cart_input);
                }
                else {
                    cart->add($cart_input);
                }

                unless ($cart_item) {
                    warning "Cart error: ", cart->error;
                    $values{cart_error} = cart->error;
                }
            }
        }

        # add stuff useful for cart display
        $values{cart} = cart->items;
        $values{cart_subtotal} = cart->subtotal;
        $values{cart_total} = cart->total;

        # call before_cart_display route so template tokens
        # can be injected
        execute_hook('before_cart_display', \%values);

        template $routes_config->{cart}->{template}, \%values;
    }
}

1;
