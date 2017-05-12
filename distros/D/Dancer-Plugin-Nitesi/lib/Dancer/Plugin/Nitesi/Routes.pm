package Dancer::Plugin::Nitesi::Routes;

use Dancer ':syntax';
use Dancer::Plugin;
use Dancer::Plugin::Nitesi;
use Dancer::Plugin::Nitesi::Routes::Cart;
use Dancer::Plugin::Nitesi::Routes::Checkout;

=head1 NAME

Dancer::Plugin::Nitesi::Routes - Routes for Nitesi Shop Machine

=head2 ROUTES

The following routes are automatically created by this plugin:

=over 4

=item cart (C</cart>)

Route for displaying and updating the cart.

=item checkout (C</checkout>)

Route for the checkout process.

=item navigation

Route for displaying navigation pages, for example
categories and menus.

=item product

Route for displaying products.

=back

=head2 CONFIGURATION

The template for each route type can be configured:

    plugins:
      Nitesi::Routes:
        cart:
          template: cart
        checkout:
          template: checkout
        navigation:
          template: listing
        product:
          template: product

This sample configuration shows the current defaults.

=head2 HOOKS

The following hooks are available to manipulate the values
passed to the templates:

=over 4

=item before_product_display

The hook sub receives the product data as hash reference.

=item before_cart_display

=item before_checkout_display

=item before_navigation_display

The hook sub receives the navigation data as hash reference.
The list of products is the value of the C<products> key.

=back

=cut

register shop_setup_routes => sub {
    _setup_routes();
};

register_hook (qw/before_product_display before_navigation_display/);
register_plugin;

our %route_defaults = (cart => {template => 'cart'},
                       checkout => {template => 'checkout'},
                       navigation => {template => 'listing'},
                       product => {template => 'product'});

sub _setup_routes {
    my $plugin_config = plugin_setting;

    # update settings with defaults
    my $routes_config = _config_routes($plugin_config, \%route_defaults);

    # routes for cart
    my $cart_sub = Dancer::Plugin::Nitesi::Routes::Cart::cart_route($routes_config);
    get '/cart' => $cart_sub;
    post '/cart' => $cart_sub;

    # routes for checkout
    my $checkout_sub = Dancer::Plugin::Nitesi::Routes::Checkout::checkout_route($routes_config);
    get '/checkout' => $checkout_sub;
    post '/checkout' => $checkout_sub;

    # fallback route for flypage and navigation
    get qr{/(?<path>.+)} => sub {
        my $path = captures->{'path'};
        my $product;

        # check for a matching product by uri
        my $product_result = shop_product->search(where => {uri => $path});

        if (@$product_result > 1) {
            die "Ambigious result on path $path.";
        }

        if (@$product_result == 1) {
            $product = shop_product($product_result->[0]->{sku})->load;
        }
        else {
            # check for a matching product by sku
            $product = shop_product($path);

            if ($product->load) {
                if ($product->uri
                    && $product->uri ne $path) {
                    # permanent redirect to specific URL
                    debug "Redirecting permanently to product uri ", $product->uri,
                        " for $path.";
                    return redirect(uri_for($product->uri), 301);
                }
            }
            else {
                # no matching product found
                undef $product;
            }
        }

        if ($product) {
            if ($product->inactive) {
                # discontinued
                status 'not_found';
                forward 404;
            }
            else {
                # flypage
                execute_hook('before_product_display', $product);
                return template $routes_config->{product}->{template}, $product;
            }
        }

        # first check for navigation item
        my $result = shop_navigation->search(where => {uri => $path});

        if (@$result > 1) {
            die "Ambigious result on path $path.";
        }

        if (@$result == 1) {
            # navigation item found

            my $nav = $result->[0];

            my $pkeys = shop_navigation($result->[0]->{code})->assigned(shop_product);

            my $products = [grep {! $_->{inactive}} map {shop_product($_)->dump} @$pkeys];

            my $tokens = {navigation => $nav,
                          products => $products,
                         };

            execute_hook('before_navigation_display', $tokens);

            return template $nav->template || $routes_config->{navigation}->{template}, $tokens;
        }

        # display not_found page
        status 'not_found';
        forward 404;
    };
}

sub _config_routes {
    my ($settings, $defaults) = @_;
    my ($key, $vref, $name, $value, $set_value);

    unless (ref($defaults)) {
        return;
    }

    while (($key, $vref) = each %$defaults) {
        if (exists $settings->{$key}) {
            # recurse
            _config_routes($settings->{$key}, $defaults->{$key});
        }
         else {
            $settings->{$key} = $defaults->{$key};
        }
    }

    return $settings;
}

1;
