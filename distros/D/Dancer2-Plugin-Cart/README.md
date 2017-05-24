# NAME

Dancer2::Plugin::Cart - ECommerce Cart Plugin for Dancer2

# VERSION

Version 1.0000

# DESCRIPTION

This plugin provides a easy way to manage a shopping cart in Dancer2.
All the information and data structure of the plugin will be managed by
the session, so a good idea is to use a plugin in order to store the
session data in the database.

It was designed to be used on new or existing database, providing a lot
of hooks in order to fit customizable solutions.

By default, the plugin is going to search default templates on the views
directory; if the view doesn't exists, the plugin will render and inline
templates provided by the plugin.

An script file has been added in order to generate the template views
of each stage of a checkout, and the user will be able to adapt it to
their needs.

The script is `create_cart_views` and needs to be run on the root
directory of the Dancer2 app. The default views assume that you are
using "Template Toolkit" as the template engine.


# SYNOPSIS

1. In order to use the plugin, you need to configure at least some products.

        plugins:
          Cart:
            product_list:
              - ec_sku: 'SU01'
                ec_price: 15
              - ec_sku: 'SU02'
                ec_price: 20

2. Install the module with [cpanminus](https://cpanmin.us/):

        cpanm Dancer2::Plugin::Cart

3. Use the library

    In your App.pm add:

        use Dancer2::Plugin::Cart;


## Configuration Options:

    * products_view_template
        * Define a template to use to show the products 
    * cart_view_template
        * Define a template to use to show cart info 
    * cart_receipt_template
        * Define a template to use to show receipts 
    * shipping_view_template
        * Define a template to use to show shipping form
    * billing_view_template
        * Define a template to use to show billing form
    * review_view_template
        * Define a template to use to show review page
    * receipt_view_template
        * Define a template to use to show receipt page
    * default_routes
        * default 1, to exclude all routes, set to 0
    * excluded_routes
        * Array defining the routes to be excluded.
## Routes
    * get /products
      List of products
    * get /cart
      Cart info
    * post /cart/add
      To add a product to the cart
    * get /cart/clear
      To reset the cart
    * get /cart/shipping
      To show shipping form
    * post /cart/shipping
      To store data on session variable
    * get /cart/billing
      To show billing form
    * post /cart/billing
      To store data on session variable
    * get /cart/review
      To show a summary of the cart
    * post /cart/checkout
      To place orders
    * get /cart/receipt
      To show the results of placing an order
      
## Keywords:

    * products
        * Returns products defined on the structure session('ec_cart')->{products}
    * cart
        * Returns the cart structure.
        * Refers: session('ec_cart')->{cart}
        * Use: subtotal, quantity, and total keywords
        * Hooks: before_cart, after_cart
    * cart_add
        * Process cart_add form and check errors on session('ec_cart')->{add}->{error}
        * Delete session('ec_cart')->{add} after success. 
        * Hooks: validate_cart_add_params, before_cart_add, after_cart_add
    * cart_add_item
        * Check if the product exists, and add/sub the quantity.
        * Calculate ec_subtotal
        * Return product added.
    * clear_cart
        Delete ec_cart session variable
        * Hooks: before_clear_cart, after_clear_cart
    * subtotal
        * Calculate subtotal of the cart
        * Hooks: before_subtotal, after_subtotal
    * quantity
        * Calculate total items on the cart
        * Hooks: before_quantity, after_quantity
    * shipping
        * Process shipping form and check errors on session('ec_cart')->{shipping}->{form}
        * Hooks: validate_shipping_params, before_shipping, after_shipping
    * billing
        * Process billing form and check errors on session('ec_cart')->{billing}->{form}
        * Hooks: validate_billing_params, before_billing, after_billing
    * checkout
        * Hooks: validate_checkout_params, checkout
    * close_cart
        * Set status 1 to session('ec_cart')->{cart}->{status}
        * Hooks: before_close_cart, after_close_cart 
    * adjustments
        * Set default adjustments
        * Hooks: adjustments

## Hooks:

    * before_cart
    * after_cart
    * validate_cart_add_params
    * before_cart_add
    * after_cart_add
    * before_cart_add_item
    * after_cart_add_item
    * validate_shipping_params
    * before_shipping
    * after_shipping
    * validate_billing_params
    * before_billing
    * after_billing
    * validate_checkout_params
    * before_checkout
    * checkout
    * after_checkout
    * before_close_cart
    * after_close_cart
    * before_clear_cart
    * after_clear_cart
    * before_subtotal
    * after_subtotal
    * before_quantity
    * after_quantity
    * adjustments


## Session structure:
```
ec_cart => {
  products => [
    {
      ec_sku => 'SU01',
      ec_price => 10
    }
  ],
  cart => {
    items => [
      {
        ec_sku => 'SU01',
        ec_price => 10,
        ec_quantity => 1.
        ec_subtotal => 10
      }
    ],
    adjustments => [
                       {
                         value => 0,
                         description => 'Discounts'
                       },
                       {
                         description => 'Shipping',
                         value => 0
                       },
                       {
                         description => 'Taxes',
                         value => 0
                       }
                     ],
    subtotal => 10,
    total => 10,
    quantity => 1,
  },
  shipping => {
    form => {
      email => 'email@domain.com'
    }
  },
  billing => {
    form => {
      email => 'email@domain.com'
    }
  }
}
```

# BUGS
Please use GitHub issue tracker
[here](https://github.com/YourSole/Cart/issues).

# AUTHOR

    YourSole Core Developers
##  CORE DEVELOPERS

    Andrew Baerg
    Ruben Amortegui

# CONTRIBUTORS

    Josh Lavin

# COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Ruben Amortegui.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.
