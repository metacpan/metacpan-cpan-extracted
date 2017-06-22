package Dancer2::Plugin::Cart;
# ABSTRACT: Cart Plugin for Dancer2 app.
use strict;
use warnings;
use Dancer2::Plugin;
use Dancer2::Plugin::Cart::InlineViews;
use JSON;
our $VERSION = '1.0001';  #Version


BEGIN{
  has 'product_list' => (
    is => 'ro',
    from_config => 1,
    default => sub { [] }
  );

  has 'products_view_template' => (
    is => 'ro',
    from_config => 'views.products',
    default => sub {}
  );

  has 'cart_view_template' => (
    is => 'ro',
    from_config => 'views.products',
    default => sub {}
  );

  has 'cart_receipt_template' => (
    is => 'ro',
    from_config => 'views.receipt',
    default => sub {}
  );

  has 'shipping_view_template' => (
    is => 'ro',
    from_config => 'views.shipping',
    default => sub {}
  );

  has 'billing_view_template' => (
    is => 'ro',
    from_config => 'views.billing',
    default => sub {}
  );

  has 'review_view_template' => (
    is => 'ro',
    from_config => 'views.review',
    default => sub {}
  );

  has 'receipt_view_template' => (
    is => 'ro',
    from_config => 'views.receipt',
    default => sub {}
  );

  has 'default_routes' => (
    is => 'ro',
    from_config => 1,
    default => sub { '1' }
  );

  has 'excluded_routes' => (
    is => 'ro',
    from_config => 1,
    default => sub { [] }
  );

  plugin_keywords qw/ 
    adjustments
    billing
    cart
    cart_add
    cart_add_item
    checkout
    clear_cart
    close_cart
    products
    quantity
    subtotal
    shipping
    total
  /;

  plugin_hooks qw/
		products
    before_cart
    after_cart
    validate_cart_add_params
    before_cart_add
    after_cart_add
    validate_shipping_params
    before_shipping
    after_shipping
    validate_billing_params
    before_billing
    after_billing
    validate_checkout_params
    checkout
    before_close_cart
    after_close_cart
    before_clear_cart
    after_clear_cart
    before_subtotal
    after_subtotal
    before_total
    after_total
    adjustments
  /;
}

sub BUILD {
  my $self = shift;
  #Create a session 
  my $settings = $self->app->config;
  my $excluded_routes = $self->excluded_routes;

  if( $self->default_routes ){  
    $self->app->add_route(
      method => 'get',
      regexp => '/products',
      code   => sub { 
        my $app = shift;
        #generate session if didn't exists
        $app->session;
        my $template = $self->products_view_template || 'products' ;
        if( -e $self->app->config->{views}.'/'.$template.'.tt' ) {
          $app->template( $template, {
            product_list => $self->products
          },
					{
						layout => 'cart.tt'
					});
        }
        else{
          _products_view({ product_list => $self->products });
        }
      },
    )if !grep { $_ eq 'products' }@{$excluded_routes};

    $self->app->add_route(
      method => 'get',
      regexp => '/cart',
      code => sub {
        my $app = shift;
        my $cart = $self->cart;
        #Generate session if didn't exists
        $app->session;
        my $template = $self->cart_view_template || 'cart/cart' ;
        my $page = "";
        if( -e $self->app->config->{views}.'/'.$template.'.tt' ) {
          $page = $app->template( $template, {
            ec_cart => $app->session->read('ec_cart'),
          },
					{
						layout => 'cart.tt'	
					} );
        }
        else{
           $page = _cart_view({ ec_cart => $app->session->read('ec_cart') });
        }
        my $ec_cart = $app->session->read('ec_cart');
        delete $ec_cart->{add}->{error} if $ec_cart->{add}->{error};
        $app->session->write( 'ec_cart', $ec_cart );
        $page;
      }
    )if !grep { $_ eq 'cart' }@{$excluded_routes};

    $self->app->add_route(
      method => 'post',
      regexp => '/cart/add',
      code => sub {
        my $app = shift;
        $self->cart_add;
        $app->redirect('/cart');
      }
    )if !grep { $_ eq 'cart/add' }@{$excluded_routes};


    $self->app->add_route(
      method => 'get',
      regexp => '/cart/clear',
      code => sub {
        my $app = shift;
        $self->clear_cart;
        $app->redirect('/cart');
      } 
    )if !grep { $_ eq 'cart/clear' }@{$excluded_routes};

    $self->app->add_route(
      method => 'get',
      regexp => '/cart/shipping',
      code => sub {
        my $app = shift;
        my $cart = $self->cart;
        my $template = $self->shipping_view_template || 'shipping';
        my $page = "";
        if( -e $app->config->{views}.'/cart/'.$template.'.tt' ) {
            $page = $app->template ( 'cart/'.$template, {
            ec_cart => $app->session->read('ec_cart'),
          },
					{
						layout => 'cart.tt'
					});
        }
        else{
          $page = _shipping_view({ ec_cart => $app->session->read('ec_cart') });
        }
        my $ec_cart = $app->session->read('ec_cart');
        delete $ec_cart->{shipping}->{error} if $ec_cart->{shipping}->{error};
        $app->session->write( 'ec_cart', $ec_cart );
        $page;
      }
    )if !grep { $_ eq 'cart/shipping' }@{$excluded_routes}; 
  
    $self->app->add_route(
      method => 'post',
      regexp => '/cart/shipping',
      code => sub {
        my $app = shift;
        $self->shipping;
        $app->redirect('/cart/billing');
      }
    )if !grep { $_ eq 'cart/shipping' }@{$excluded_routes}; 

    $self->app->add_route(
      method => 'get',
      regexp => '/cart/billing',
      code => sub {
        my $app = shift;
        my $cart = $self->cart;
        my $template = $self->billing_view_template || 'billing' ;
        my $page = "";
        if( -e $app->config->{views}.'/cart/'.$template.'.tt' ) {
            $page = $app->template( 'cart/'.$template, {
            ec_cart => $app->session->read('ec_cart'),
          },
					{
						layout => 'cart.tt'
					}
					);
        }
        else{
          $page = _billing_view({ ec_cart => $app->session->read('ec_cart') });
        }
        my $ec_cart = $app->session->read('ec_cart');
        delete $ec_cart->{billing}->{error} if $ec_cart->{billing}->{error};
        $app->session->write( 'ec_cart', $ec_cart );
        $page;
      }
    )if !grep { $_ eq 'cart/billing' }@{$excluded_routes}; 

    $self->app->add_route(
      method => 'post',
      regexp => '/cart/billing',
      code => sub {
        my $app = shift;
        $self->billing; 
        $app->redirect('/cart/review');
      }
    )if !grep { $_ eq 'cart/billing' }@{$excluded_routes}; 
    
    $self->app->add_route(
      method => 'get',
      regexp => '/cart/review',
      code => sub { 
        my $app = shift;
        my $cart = $self->cart;
        my $page = "";
        my $template = $self->review_view_template || 'review' ;
        if( -e $app->config->{views}.'/cart/'.$template.'.tt' ) {
            $page = $app->template( 'cart/'.$template,{
              ec_cart => $app->session->read('ec_cart'),
            },
						{
							layout => 'cart.tt'
						});
        }
        else{
          $page = _review_view( { ec_cart => $app->session->read('ec_cart') } );
        }
        my $ec_cart = $app->session->read('ec_cart');
        delete $ec_cart->{checkout}->{error} if $ec_cart->{checkout}->{error};
        $app->session->write('ec_cart',$ec_cart);
        $page;
      }
    )if !grep { $_ eq 'cart/review' }@{$excluded_routes}; 

    $self->app->add_route(
      method => 'post',
      regexp => '/cart/checkout',
      code => sub {
        my $app = shift;
        $self->checkout;
        $app->redirect('/cart/receipt');
      }
    )if !grep { $_ eq 'cart/receipt' }@{$excluded_routes}; 

    $self->app->add_route(
      method => 'get',
      regexp => '/cart/receipt',
      code => sub {
        my $app = shift;
        my $template = $self->receipt_view_template || 'receipt' ;
        my $page = "";
				my $ec_cart = $app->session->read('ec_cart');
        if( -e $app->config->{views}.'/cart/'.$template.'.tt' ) {
          $page = $app->template( 'cart/'.$template, 
					{ 
	  				ec_cart => $ec_cart 
		      },
					{
						layout => 'cart.tt'
					});
        }
        else{
          $page = _receipt_view({ ec_cart => $ec_cart });
        }
        $app->session->delete('ec_cart');
        $page;
      }
    )if !grep { $_ eq 'cart/receipt' }@{$excluded_routes}; 
  }
};


sub products {
  my ( $self ) = @_;
  my $app = $self->app;
	my $ec_cart = $self->cart;
	if ( $self->product_list ){
    $ec_cart->{products} = $self->product_list;
    $app->session->write( 'ec_cart', $ec_cart );
	}
  $app->execute_hook('plugin.cart.products');
  $ec_cart = $self->cart;
	return $ec_cart->{products};
}

sub cart_add_item {
  my ( $self, $product ) = @_;
  my $app = $self->app;
	my $index = 0;
	my $ec_cart = $self->cart; 
	$ec_cart->{cart}->{items} = [] unless $ec_cart->{cart}->{items};
	foreach my $cart_product ( @{$ec_cart->{cart}->{items}} ){
    if( $cart_product->{ec_sku} eq $product->{ec_sku} ){
			$cart_product->{ec_quantity} += $product->{ec_quantity};
			$cart_product->{ec_subtotal} = $cart_product->{ec_quantity} * $cart_product->{ec_price};
			if(  $cart_product->{ec_quantity} <= 0 ){
			  splice @{$ec_cart->{cart}->{items}}, $index, 1;
			}
  		$app->session->write( 'ec_cart', $ec_cart );
			return $cart_product;
    }
		$index++;
  }
	
  foreach my $product_item ( @{$self->products} ){
		if( $product_item->{ec_sku} eq $product->{ec_sku} ){
      foreach my $k (keys %{ $product_item }) {
        $product->{$k} = $product_item->{$k};
      }
			$product->{ec_subtotal} = $product->{ec_quantity} * $product->{ec_price};
		}
	}
	push @{$ec_cart->{cart}->{items}}, $product;
  $app->session->write( 'ec_cart', $ec_cart );
	
	return $product;
};

sub cart {
  my ( $self ) = @_;
  my $app = $self->app;
  $app->execute_hook('plugin.cart.before_cart');
  my $ec_cart = $app->session->read('ec_cart');
	$ec_cart->{cart}->{items} = [] unless $ec_cart->{cart}->{items};
	$app->session->write('ec_cart', $ec_cart);
	$self->subtotal;
  $self->adjustments;
  $self->total;
  $ec_cart = $app->session->read('ec_cart');
  $app->execute_hook('plugin.cart.after_cart');
  $ec_cart = $app->session->read('ec_cart');
  return $ec_cart;
};

sub quantity {
  my ($self, $params) = @_;
  my $app = $self->app;

  $self->execute_hook ('plugin.cart.before_quantity');
  my $ec_cart = $app->session->read('ec_cart');
  my $quantity = 0;
  foreach my $item_quantity ( @{ $ec_cart->{cart}->{items} } ){
    $quantity += $item_quantity->{ec_quantity} if $item_quantity->{ec_quantity};
  }
  $ec_cart->{cart}->{quantity} = $quantity;
  $app->session->write('ec_cart',$ec_cart);
  $self->execute_hook ('plugin.cart.after_quantity');
  $ec_cart = $app->session->read('ec_cart');
  $ec_cart->{cart}->{quantity};
}

sub subtotal{
  my ($self, $params) = @_;
  my $app = $self->app;

  $self->execute_hook ('plugin.cart.before_subtotal');
  my $ec_cart = $app->session->read('ec_cart');
  my $subtotal = 0;
  foreach my $item_subtotal ( @{ $ec_cart->{cart}->{items} } ){
    $subtotal += $item_subtotal->{ec_subtotal} if $item_subtotal->{ec_subtotal};
  }
  $ec_cart->{cart}->{subtotal} = $subtotal;
  $app->session->write('ec_cart',$ec_cart);
  $self->execute_hook ('plugin.cart.after_subtotal');
  $ec_cart = $app->session->read('ec_cart');
  $ec_cart->{cart}->{subtotal};
}


sub clear_cart {
  my ($self, $params ) = @_;
  $self->execute_hook ('plugin.cart.before_clear_cart');
  $self->app->session->delete('ec_cart');
  $self->execute_hook ('plugin.cart.after_clear_cart');
}


sub cart_add {
  my ($self, $params) = @_;

  my $app = $self->app;
  my $form_params = { $app->request->params };
  my $product = undef;
  
  #Add params to ec_cart session
  my $ec_cart = $app->session->read( 'ec_cart' );
  $ec_cart->{add}->{form} = $form_params; 
  $app->session->write( 'ec_cart', $ec_cart );

  #Param validation
  $app->execute_hook( 'plugin.cart.validate_cart_add_params' );
  $ec_cart = $app->session->read('ec_cart');
  
  if ( $ec_cart->{add}->{error} ){
    $self->app->redirect( $app->request->referer || $app->request->uri  );
  }
  else{
    #Cart operations before add product to the cart.
    $app->execute_hook( 'plugin.cart.before_cart_add' );
    $ec_cart = $app->session->read('ec_cart');

    if ( $ec_cart->{add}->{error} ){
      $self->app->redirect( $app->request->referer || $app->request->uri  );
    }
    else{
      $product = $self->cart_add_item({
          ec_sku => $ec_cart->{add}->{form}->{'ec_sku'},
          ec_quantity => $ec_cart->{add}->{form}->{'ec_quantity'},
        }
      );
      #Cart operations after adding product to the cart
      $app->execute_hook( 'plugin.cart.after_cart_add' );
      $ec_cart = $app->session->read('ec_cart');
      delete $ec_cart->{add};
      $app->session->write( 'ec_cart', $ec_cart );
    }
  }
}

sub shipping {
  my $self = shift;
  my $app = $self->app;
  my $params = { $app->request->params };
  #Add params to ec_cart session
  my $ec_cart = $app->session->read( 'ec_cart' );
  $ec_cart->{shipping}->{form} = $params; 
  $app->session->write( 'ec_cart', $ec_cart );
  $app->execute_hook( 'plugin.cart.validate_shipping_params' );
  $ec_cart = $app->session->read('ec_cart');
  if ( $ec_cart->{shipping}->{error} ){ 
    $app->redirect( $app->request->referer || $app->request->uri );
  }
  else{
    $app->execute_hook( 'plugin.cart.before_shipping' );
    my $ec_cart = $app->session->read('ec_cart');

    if ( $ec_cart->{shipping}->{error} ){
      
      $app->redirect( ''.$app->request->referer || $app->request->uri  );
    }
    $app->execute_hook( 'plugin.cart.after_shipping' );
  }
}

sub billing{
  my $self = shift;
  my $app = $self->app;
  my $params = { $app->request->params };
  #Add params to ec_cart session
  my $ec_cart = $app->session->read( 'ec_cart' );
  $ec_cart->{billing}->{form} = $params; 
  $app->session->write( 'ec_cart', $ec_cart );
  $app->execute_hook( 'plugin.cart.validate_billing_params' );
  $ec_cart = $app->session->read('ec_cart');
  if ( $ec_cart->{billing}->{error} ){
    $app->redirect( $app->request->referer || $app->request->uri );
  }
  else{
    $app->execute_hook( 'plugin.cart.before_billing' );
    my $ec_cart = $app->session->read('ec_cart');

    if ( $ec_cart->{billing}->{error} ){
      $app->redirect( $app->request->referer || $app->request->uri  );
    }
    $app->execute_hook( 'plugin.cart.after_billing' );
  }
}

sub checkout{
  my $self = shift;
  my $app = $self->app;
  my $params = ($app->request->params);
  my $ec_cart = $app->session->read( 'ec_cart' );
  $ec_cart->{checkout}->{form} = $params;
  $app->session->write( 'ec_cart', $ec_cart );
  $app->execute_hook( 'plugin.cart.validate_checkout_params' );
  $ec_cart = $app->session->read('ec_cart');
  if ( $ec_cart->{checkout}->{error} ){
    $app->redirect( $app->request->referer || $app->request->uri  );
  }
  else{
    $app->execute_hook( 'plugin.cart.checkout' );
    $ec_cart = $app->session->read('ec_cart');
    if ( $ec_cart->{checkout}->{error} ){
      $app->redirect( $app->request->referer || $app->request->uri );
    }
    else{
      $self->close_cart;
    }
  }
}

sub close_cart{
  my ($self, $params) = @_;
  my $app = $self->app;
  my $ec_cart = $self->cart;
  return { error => 'Cart without items' } unless @{$ec_cart->{cart}->{items}} > 0;
  $app->execute_hook( 'plugin.cart.before_close_cart' ); 
	$ec_cart->{cart}->{session} = $app->session->id;
	$ec_cart->{cart}->{status} = 1;
  $app->session->write('ec_cart', $ec_cart );
  $app->execute_hook( 'plugin.cart.after_close_cart' ); 
}

sub adjustments {
  my ($self, $params) = @_;
  my $app = $self->app;
  my $ec_cart = $app->session->read('ec_cart');
  my $default_adjustments = [
    {
      description => 'Discounts',
      value => '0'
    },
    {
      description => 'Shipping',
      value => '0'
    },
    {
      description => 'Taxes',
      value => '0'
    },
  ];
  $ec_cart->{cart}->{adjustments} = $default_adjustments;
  $app->session->write( 'ec_cart', $ec_cart );
  $app->execute_hook('plugin.cart.adjustments');
}


sub total {
  my ($self) = shift;
  my $app = $self->app;
  $app->execute_hook('plugin.cart.before_total');
  my $ec_cart = $app->session->read('ec_cart');
  my $total = 0;
  $total += $ec_cart->{cart}->{subtotal};
  foreach my $adjustment ( @{$ec_cart->{cart}->{adjustments}}){
    $total += $adjustment->{value};
  }
  $ec_cart->{cart}->{total} = $total;
  $app->session->write('ec_cart', $ec_cart );
  $app->execute_hook('plugin.cart.after_total');
  return $ec_cart->{cart}->{total};
}



1;
__END__


=pod

=head1 NAME

Dancer2::Plugin::Cart - Cart interface for Dancer2 applications

=head1 VERSION

version 1.0001

=head1 SYNOPSIS

    use Dancer2;
    use Dancer2::Plugin::Cart;


=head1 DESCRIPTION

This plugin provides a easy way to manage a shopping cart in dancer2.  All the information and data structure of the plugin will be manage by the session, so a good idea is to use a plugin in order to store the session data in the database.  

It was designed to be used on new or existing database, providing a lot of hooks in order to fit customizable solutions.

By default, the plugin is going to search default templates on the views directory, if the view doesn't exists, the plugin will render and inline templates provided by the plugin.

An script file has been added in order to generate the template views of each stage of a checkout, and the user will be able to adapt it to their needs.

The script is create_cart_views and needs to be run on the root directory of the dancer2 app.  The default views assume that you are using "Template Toolkit" as the template engine.

=encoding utf8

=head1 CONFIGURATION

=over 4

=item C<environment>

  plugins:
    Cart:
      product_list:
        - ec_sku: 'SU02'
          ec_price: 16
        - ec_sku: 'SU02'
          ec_price: 21

=item C<Options>

    products_view_template
      - Define a template to use to show the products 
    cart_view_template
      - Define a template to use to show cart info 
    cart_receipt_template
      - Define a template to use to show receipts 
    shipping_view_template
      - Define a template to use to show shipping form 
    billing_view_template
      - Define a template to use to show billing form 
    review_view_template
      - Define a template to use to show review page 
    receipt_view_template
      - Define a template to use to show receipt page 
    default_routes
      - default 1, to exclude all routes, set to 0
    excluded_routes
      - Array defining the routes to be excluded.

=back

=head1 ROUTES

=head2 get /products

  List of products

=head2 get /cart

  Cart info

=head2 post /cart/add

  To add a product to the cart

=head2 get /cart/clear

  To reset the cart

=head2 get /cart/shipping

  To show shipping form

=head2 post /cart/shipping

  To store data on session variable

=head2 get /cart/billing

  To show billing form

=head2 post /cart/billing

  To store data on session variable

=head2 get /cart/review

  To show a summary of the cart

=head2 post /cart/checkout

  To place orders

=head2 get /cart/receipt

  To show the results of placing an order


=head1 FUNCTIONS

=head2 products

Return the list of products and fill the ec_cart->{products} session variable.

=head2 cart

Return a ec_cart Hashref with the updated info.

Use: subtotal, quantity, and total keywords

Call hooks: before_cart, after_cart

=head2 cart_add

Add product to the cart

Process cart_add form and check errors on session('ec_cart')->{add}->{error}

Delete session('ec_cart')->{add} after success 

Call hooks: validate_cart_add_params, before_cart_add, after_cart_add

=head2 cart_add_item

Check if the product exists, adn add/sub the quantity

Calculate ec_subtotal for each item

Return product added

=head2 clear_cart

Delete ec_cart session variable

Call hooks: before_clear_cart, after_clear_cart

=head2 subtotal

Calculate and return the subtotal (sum of ec_subtotal of each product)

Call hooks: before_subtotal, after_subtotal

=head2 quantity

Calculate and return the quantity (sum of ec_quantity of each product)

Call hooks: before_quantity, after_quantity

=head2 billing

Load the ec_cart structure and check if there is any error on ec_cart->{billing}->{error}.

In case of error, the user is redirected to the billing route, other wise pass to the 

Call hooks: validate_billing_params, before_bililng, after_billing_

=head2 shipping

Load the ec_cart structure and check if there is any error on ec_cart->{shipping}->{error}

In case of error, the user is redirected to the shipping route.

Call hooks: validate_shipping_params, before_shipping, after_shipping

=head2 checkout

Load the ec_cart structure check if there is any error on ec_cart->{checkout}->{error};

Call hook: checkout

=head2 close_cart

Add status 1 to the ec_cart structure.

Call hooks: before_close_cart and after_close_cart

=head2 adjustments

Add default adjustments to the ec_cart structure. The default adjustments are:  Discounts, Shipping, Taxes.
Call hook adjustments

=head1 HOOKS

Hooks are called before|after|as a function.  The purpose of the hooks is to manipulate the data structure 
defined to ec_cart.

=head2 before_cart

=head2 after_cart

=head2 validate_cart_add_params

=head2 before_cart_add

=head2 after_cart_add

=head2 validate_shipping_params

=head2 before_shipping

=head2 after_shipping

=head2 validate_billing_params

=head2 before_billing

=head2 after_billing

=head2 validate_checkout_params

=head2 checkout

To implement the checkout step.

=head2 before_close_cart

=head2 after_close_cart

=head2 before_clear_cart

=head2 after_clear_cart

=head2 before_subtotal

=head2 after_subtotal

=head2 before_quantity

=head2 after_quantity

=head2 before_total

=head2 after_total

=head2 adjustments

Add adjustments (This hook is called is called by cart function).

=head1 AUTHORS

=head2 CORE DEVELOPERS

    Andrew Baerg
    Ruben Amortegui

=head1 AUTHOR

    YourSole Core Developers

=head1 CONTRIBUTORS

    Josh Lavin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Ruben Amortegui.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
