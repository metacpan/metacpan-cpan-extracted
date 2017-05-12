package Dancer2::Plugin::Interchange6::Routes::Cart;

use Try::Tiny;

=head1 NAME

Dancer2::Plugin::Interchange6::Routes::Cart - Cart routes for Interchange6 Shop Machine

=cut

=head1 FUNCTIONS

=head2 cart_route

Returns the cart route based on the plugin configuration.

=cut

sub cart_route {
    my $plugin = shift;

    return sub {
        my $app    = shift;
        my $params = $app->request->parameters;

        my ( $product, $cart_input, $cart_product, $roles, @errors );

        my $cart_name = $params->get('cart');

        my $cart =
          $cart_name ? $plugin->shop_cart($cart_name) : $plugin->shop_cart;

        $app->log( "debug", "cart_route cart name: ", $cart->name );

        if ( my @skus = $params->get_all('remove') ) {

            # remove items from cart

            foreach my $sku (@skus) {
                try {
                    $cart->remove($sku);
                }
                catch {
                    $app->log( "warning", "Cart remove $sku error: $_" );
                    push @errors, "Failed to remove product $sku from cart: $_";
                };
            }

            # if GET then URL now contains ugly query params so redirect
            return $app->redirect('/cart') if $app->request->is_get;

        }
        elsif ( $params->get('update')
            && defined $params->get('quantity') )
        {

            my $sku = $params->get('update');
            my $qty = $params->get('quantity');

            # update existing cart product

            $app->log( "debug", "Update $sku with quantity $qty" );

            try {
                $cart->update( $sku => $qty );
            }
            catch {
                $app->log( "warning", "Update cart product $sku error: $_" );
                push @errors, "Failed to update product $sku in cart: $_";
            };
        }

        if ( my $sku = $params->get('sku') ) {

            # add new product

            # we currently only support one product at a time

            $product = $plugin->shop_product($sku);

            unless ( defined $product ) {
                $app->log( "warning",
                    "sku $sku not found in POST /cart: $input" );
                $app->session->write( shop_cart_error =>
                      { message => "Product not found with sku: $sku" } );
                return $app->redirect('/');
            }

            if ( defined $product->canonical_sku ) {

                # this is a variant so we need to add in variant info
                # into $params if missing

                my $rset = $product->product_attributes->search(
                    {
                        'attribute.type' => 'variant',
                    },
                    {
                        prefetch => [
                            'attribute',
                            {
                                product_attribute_values => 'attribute_value'
                            }
                        ],
                    }
                );
                while ( my $result = $rset->next ) {
                    my $name = $result->attribute->name;

                    # WTF! why do we get a resultset of pavs? Surely there
                    # should be only one related pav for pa?
                    my $value =
                      $result->product_attribute_values->first->attribute_value
                      ->value;

                    $params->set( $name => $value )
                      unless defined $params->get($name);
                }
            }

            # retrieve product attributes for possible variants
            my $attr_ref = $product->attribute_iterator( hashref => 1 );
            my %user_input;

            if ( keys %$attr_ref ) {

                for my $name ( keys %$attr_ref ) {
                    $user_input{$name} = $params->get($name);
                }

                $app->log(
                    "debug", "Attributes for $input: ",
                    $attr_ref, ", user input: ",
                    \%user_input
                );
                my %match_info;

                unless ( $cart_product =
                    $product->find_variant( \%user_input, \%match_info ) )
                {
                    $app->log( "warning", "Variant not found for ",
                        $product->sku );

                    $app->session->write(
                        shop_cart_error => {
                            message => 'Variant not found.',
                            info    => \%match_info
                        }
                    );

                    return $app->redirect( $product->uri );
                }
            }
            else {
                # product without variants
                $cart_product = $product;
            }

            my $quantity =
              $params->get('quantity') ? $params->get('quantity') : 1;

            try {
                $cart->add(
                    {
                        dbic_product => $cart_product,
                        sku          => $cart_product->sku,
                        quantity     => $quantity
                    }
                );
            }
            catch {
                $app->log( "warning", "Cart add error: $_" );
                push @errors, "Failed to add product to cart: $_";
            };
        }

        # add stuff useful for cart display
        my $values = {
            cart_subtotal => $cart->subtotal,
            cart_total    => $cart->total,
            cart          => $cart->products,
        };
        $values->{cart_error} = join( ". ", @errors )
          if scalar @errors;

        # call before_cart_display route so template tokens
        # can be injected
        $app->execute_hook( 'plugin.interchange6.before_cart_display',
            $values );

        $app->template( $plugin->cart_template, $values );
      }
}

1;
