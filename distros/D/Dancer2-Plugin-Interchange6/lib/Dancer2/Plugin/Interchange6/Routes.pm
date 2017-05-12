package Dancer2::Plugin::Interchange6::Routes;

use Dancer2::Plugin;
use Dancer2::Plugin::Interchange6::Routes::Account;
use Dancer2::Plugin::Interchange6::Routes::Cart;
use Dancer2::Plugin::Interchange6::Routes::Checkout;

=head1 NAME

Dancer2::Plugin::Interchange6::Routes - Routes for Interchange6 Shop Machine

=head2 shop_setup_routes

The following routes are provided by this plugin.

Active routes are automatically installed by the C<shop_setup_routes> keyword:

=over 4

=item cart (C</cart>)

Route for displaying and updating the cart.

=item checkout (C</checkout>)

Route for the checkout process (not B<active> and not recommended).

=item login (C</login>)

Login route.

=item logout (C</logout>)

Logout route.

=item navigation

Route for displaying navigation pages, for example
categories and menus.

The number of products shown on the navigation page can
be configured with the C<records> option:

  plugins:
    Interchange6::Routes:
      navigation:
        records: 20

=item product

Route for displaying products.

=back

=head2 CONFIGURATION

The template for each route type can be configured:

    plugins:
      Interchange6::Routes:
        account:
          login:
            template: login
            uri: login
            success_uri:
          logout:
            template: logout
            uri: logout
        cart:
          template: cart
          uri: cart
          active: 1
        checkout:
          template: checkout
          uri: checkout
          active: 0
        navigation:
          template: listing
          records: 0
        product:
          template: product

This sample configuration shows the current defaults.

=head2 HOOKS

The following hooks are available to manipulate the values
passed to the templates:

=over 4

=item before_product_display

The hook sub receives a hash reference, where the Product object
is the value of the C<product> key.

=item before_cart_display

=item before_checkout_display

=item before_navigation_search

This hook is called if a navigation uri is requested and before product search
queries are generated.

The hook sub receives the navigation data as hash reference:

=over 4

=item navigation

Navigation object.

=item page

Page number found at end of URI or 1 if no page number found.

=item template

Name of template.

=back

The navigation hash reference can be modified inside the hook and all changes
will be visible to the navigation route (and also the template) after the hook
returns.

=item before_navigation_display

The hook sub receives the navigation data as hash reference:

=over 4

=item navigation

Navigation object.

=item products

Product listing for this navigation item. The product listing is generated
using L<Interchange6::Schema::Result::Product/listing>.

=item pager

L<Data::Page> object for L</products>.

To get the full count of products call C<total_entries> on the Data::Page
object.

=item template

Name of template. In order to use another template, change
the value in the hashref.

    hook 'before_navigation_display' => sub {
        my $navigation_data = shift;

        if ($navigation_data->{navigation}->uri =~ /^admin/) {
             $navigation_data->{template} = 'admin_listing';
        }
    };

=back

=item before_login_display

=back

=head3 EXAMPLES

Disable parts of layout on the login view:

    hook 'before_login_display' => sub {
        my $tokens = shift;

        $tokens->{layout_noleft} = 1;
        $tokens->{layout_noright} = 1;
    };

=cut

=head1 DANCER HOOKS

The following standard L<Dancer2> hooks are used:

=head2 before

Set L<Interchange6::Schema/current_user> for the default schema
to L<Dancer2::Plugin::Auth::Extensible/logged_in_user> or C<undef>.

=cut

plugin_hooks(
    qw/before_product_display before_navigation_search
      before_navigation_display/
);

# config attributes

has login_template => (
    is          => 'ro',
    from_config => 'account.login.template',
    default     => sub { 'login' },
);

has login_uri => (
    is          => 'ro',
    from_config => 'account.login.uri',
    default     => sub { 'login' },
);

has login_success_uri => (
    is          => 'ro',
    from_config => 'account.login.success_uri',
    default     => sub { '' },
);

has logout_template => (
    is          => 'ro',
    from_config => 'account.logout.template',
    default     => sub { 'logout' },
);

has logout_uri => (
    is          => 'ro',
    from_config => 'account.logout.uri',
    default     => sub { 'logout' },
);

has cart_template => (
    is          => 'ro',
    from_config => 'cart.template',
    default     => sub { 'cart' },
);

has cart_uri => (
    is          => 'ro',
    from_config => 'cart.uri',
    default     => sub { 'cart' },
);

has cart_active => (
    is          => 'ro',
    from_config => 'cart.active',
    default     => sub { 1 },
);

has checkout_template => (
    is          => 'ro',
    from_config => 'checkout.template',
    default     => sub { 'checkout' },
);

has checkout_uri => (
    is          => 'ro',
    from_config => 'checkout.uri',
    default     => sub { 'checkout' },
);

has checkout_active => (
    is          => 'ro',
    from_config => 'checkout.active',
    default     => sub { 0 },
);

has navigation_template => (
    is          => 'ro',
    from_config => 'navigation.template',
    default     => sub { 'listing' },
);

has navigation_records => (
    is          => 'ro',
    from_config => 'navigation.records',
    default     => sub { 0 },
);

has product_template => (
    is          => 'ro',
    from_config => 'product.template',
    default     => sub { 'product' },
);

# plugins we use

has plugin_auth_extensible => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        $_[0]->app->with_plugin('Dancer2::Plugin::Auth::Extensible');
    },
    handles => [ 'logged_in_user', ],
);

has plugin_interchange6 => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        $_[0]->app->with_plugin('Dancer2::Plugin::Interchange6');
    },
    handles => [
        'shop_address',    'shop_attribute',
        'shop_cart',       'shop_charge',
        'shop_country',    'shop_message',
        'shop_navigation', 'shop_order',
        'shop_product',    'shop_redirect',
        'shop_schema',     'shop_state',
        'shop_user',
    ],
);

# other attributes

has object_autodetect => (
    is   => 'ro',
    lazy => 1,
    default =>
      sub { $_[0]->app->config->{template} eq 'template_flute' ? 1 : 0 },
);

# keywords

plugin_keywords 'shop_setup_routes';

sub shop_setup_routes {
    my $plugin = shift;
    my $app    = $plugin->app;

    my $sub;

    # display warnings
    $plugin->_config_warnings;

    # account routes
    my $account_routes =
      Dancer2::Plugin::Interchange6::Routes::Account::account_routes($plugin);

    $app->add_route(
        method => 'get',
        regexp => '/' . $plugin->login_uri,
        code   => $account_routes->{login}->{get},
    );

    $app->add_route(
        method => 'post',
        regexp => '/' . $plugin->login_uri,
        code   => $account_routes->{login}->{post},
    );

    foreach my $method ( 'get', 'post' ) {
        $app->add_route(
            method => $method,
            regexp => '/' . $plugin->logout_uri,
            code   => $account_routes->{logout}->{any},
        );
    }

    if ( $plugin->cart_active ) {

        # routes for cart
        my $cart_sub =
          Dancer2::Plugin::Interchange6::Routes::Cart::cart_route($plugin);

        foreach my $method ( 'get', 'post' ) {
            $app->add_route(
                method => $method,
                regexp => '/' . $plugin->cart_uri,
                code   => $cart_sub,
            );
        }
    }

    if ( $plugin->checkout_active ) {

        # routes for checkout
        my $checkout_sub =
          Dancer2::Plugin::Interchange6::Routes::Checkout::checkout_route(
            $plugin);

        foreach my $method ( 'get', 'post' ) {
            $app->add_route(
                method => $method,
                regexp => '/' . $plugin->checkout_uri,
                code   => $checkout_sub,
            );
        }
    }

    # fallback route for flypage and navigation
    $app->add_route(
        method => 'get',
        regexp => qr{/(?<path>.+)},
        code   => sub {
            my $app  = shift;
            my $path = $app->request->captures->{'path'};

            my $schema = $plugin->shop_schema;

            # check for a matching product by uri
            my $product =
              $plugin->shop_product->single( { uri => $path, active => 1 } );

            if ( !$product ) {

                # check for a matching product by sku
                $product = $plugin->shop_product->single(
                    { sku => $path, active => 1 } );

                if ( $product && $product->uri ) {

                    # permanent redirect to specific URL
                    $app->log( "debug",
                        "Redirecting permanently to product uri ",
                        $product->uri, " for $path." );

                    return $app->redirect(
                        $app->request->uri_for( $product->uri ), 301 );
                }
            }

            if ($product) {

                # flypage
                my $tokens = { product => $product };

                $plugin->execute_plugin_hook( 'before_product_display',
                    $tokens );

                my $output =
                  $app->template( $plugin->product_template, $tokens );

                # temporary way to erase cart errors from missing variants
                $app->session->write( shop_cart_error => undef );

                return $output;
            }

            # check for page number
            my $page;

            if ( $path =~ s%/([1-9][0-9]*)$%% ) {
                $page = $1;
            }
            else {
                $page = 1;
            }

            # first check for navigation item
            my $nav =
              $plugin->shop_navigation->single( { uri => $path, active => 1 } );

            if ( defined $nav ) {

                # navigation item found

                # retrieve navigation attribute for template
                my $template = $plugin->navigation_template;

                if ( my $attr_value = $nav->find_attribute_value('template') ) {
                    $app->log( "debug",
                            "Change template name from $template"
                          . " to $attr_value due to navigation attribute." );
                    $template = $attr_value;
                }

                my $tokens = {
                    navigation => $nav,
                    page       => $page,
                    template   => $template
                };

                $plugin->execute_plugin_hook( 'before_navigation_search',
                    $tokens );

                # Find product listing for this nav for active products only.
                # In order_by me refers to navigation_products.

                my $products =
                  $tokens->{navigation}
                  ->navigation_products->search_related('product')
                  ->active->listing->order_by('!me.priority,!product.priority');

                if ( defined $plugin->navigation_records ) {

                    # records per page is set in configuration so page the
                    # result set

                    $products = $products->rows( $plugin->navigation_records )
                      ->page( $tokens->{page} );
                }

                # get a pager

                $tokens->{pager} = $products->pager;

                # can template autodetect objects?

                if ( !$plugin->object_autodetect ) {
                    $products = [ $products->all ];
                }

                $tokens->{products} = $products;

                $plugin->execute_plugin_hook( 'before_navigation_display',
                    $tokens );

                return $app->template( $tokens->{template}, $tokens );
            }

            # check for uri redirect record
            my ( $redirect, $status_code ) = $plugin->shop_redirect($path);

            if ($redirect) {

                # redirect to specific URL
                $app->log( "debug",
                        "UriRedirect record found redirecting uri"
                      . " $redirect to $path with status code $status_code" );

                return $app->redirect( $app->request->uri_for($redirect),
                    $status_code );
            }

            # display not_found page
            $app->response->status('not_found');
            $app->forward(404);
        },
    );
}

sub _config_warnings {
    my $plugin = shift;

    if ( $plugin->navigation_records == 0 ) {
        warn __PACKAGE__, ": Maximum number of navigation records is zero.\n";
    }
}

1;
