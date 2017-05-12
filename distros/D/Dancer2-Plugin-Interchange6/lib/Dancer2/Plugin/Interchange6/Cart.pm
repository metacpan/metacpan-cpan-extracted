use utf8;

package Dancer2::Plugin::Interchange6::Cart;

=head1 NAME

Dancer2::Plugin::Interchange6::Cart

=head1 DESCRIPTION

Extends L<Interchange6::Cart> to tie cart to L<Interchange6::Schema::Result::Cart>.

=cut

use strict;
use warnings;

use Interchange6::Types -types;
use JSON::MaybeXS ();
use MooseX::CoverableModifiers;
use Module::Runtime 'use_module';

use Moo;
extends 'Interchange6::Cart';
use namespace::clean;

=head1 ATTRIBUTES

See L<Interchange6::Cart/ATTRIBUTES> for a full list of attributes
inherited by this module.

=head2 plugin

Dancer2::Plugin::Interchange6 plugin instance.

=cut

has plugin => (
    is => 'ro',
    required => 1,
);

=head2

Dancer2 app instance for L</plugin>.

=cut

has app => (
    is       => 'ro',
    lazy => 1,
    default => sub { $_[0]->plugin->app },
);

=head2 database

The database name as defined in the L<Dancer2::Plugin::DBIC> configuration.

Defaults to 'default'.

=cut

has database => (
    is       => 'ro',
    isa      => Str,
    default  => 'default',
);

=head2 dbic_cart

=cut

has dbic_cart => (
    is => 'lazy',
    isa => InstanceOf['Interchange6::Schema::Result::Cart'],
);

sub _build_dbic_cart {
    my $self = shift;

    my $cart = $self->schema->resultset('Cart')->find_or_new(
        {
            name        => $self->name,
            sessions_id => $self->sessions_id,
        },
        { key => 'carts_name_sessions_id' }
    );

    if ( $cart->in_storage ) {
        $self->app->log( 'debug', "Existing cart: ",
            $cart->carts_id, " ", $cart->name, "." );
    }
    else {
        $cart->insert;
        $self->app->log( 'debug', "New cart ", $cart->carts_id, " ",
            $cart->name, "." );
    }
    return $cart;
}

=head2 dbic_cart_products

L</dbic_cart> related resultset C<cart_products> with prefetched C<product>.

=cut

has dbic_cart_products => (
    is => 'lazy',
    isa => InstanceOf['DBIx::Class::ResultSet'],
);

sub _build_dbic_cart_products {
    return shift->dbic_cart->related_resultset('cart_products')->search(
        undef,
        {
            prefetch => 'product'
        }
    );
}

=head2 schema

DBIC schema for L</database>.

=cut

has schema => (
    is       => 'ro',
    required => 1,
);

=head2 id

Extends inherited L<Interchange6::Cart/id> attribute.

Defaults to C<id> of L</dbic_cart>.

=cut

has '+id' => (
    is => 'lazy',
);

sub _build_id {
    return shift->dbic_cart->id,
}

=head2 product_class

Inherited. Default is L<Dancer2::Plugin::Interchange6::Cart::Product>.

=cut

has '+product_class' => (
    default => __PACKAGE__ . '::Product',
);

=head2 sessions_id

Extends inherited sessions_id attribute.

Defaults to C<< session->id >>.

=cut

has '+sessions_id' => (
    is       => 'ro',
    required => 1,
);

=head1 METHODS

See L<Interchange6::Cart/METHODS> for a full list of methods inherited by
this module.

=head2 BUILD

Load existing cart from the database along with any products it contains.

=cut

sub BUILD {
    my $self = shift;
    my ( @products, $roles );

    my $rset = $self->dbic_cart_products->order_by( 'cart_position',
        'cart_products_id' );

    my $json = JSON::MaybeXS->new;

    while ( my $record = $rset->next ) {

        push @products,
          {
            dbic_product  => $record->product,
            id            => $record->cart_products_id,
            sku           => $record->sku,
            canonical_sku => $record->product->canonical_sku,
            name          => $record->product->name,
            quantity      => $record->quantity,
            price         => $record->product->price,
            uri           => $record->product->uri,
            weight        => $record->product->weight,
            combine       => $record->combine,
            $record->extra ? ( extra => $json->decode( $record->extra ) ) : (),
          };
    }

    # use seed to avoid hooks
    $self->seed( \@products );
}

=head1 METHODS

=head2 add

Add one or more products to the cart.

Possible arguments:

=over

=item * single product sku (scalar value)

=item * hashref with keys 'sku' and 'quantity' (quantity is optional and defaults to 1)

=item * an array reference of either of the above

=back

In list context returns an array of L<Interchange6::Cart::Product>s and in scalar context returns an array reference of the same.

=cut

around 'add' => sub {
    my ( $orig, $self, $args ) = @_;
    my ( @products, @ret );

    # convert to array reference if we don't already have one
    $args = [$args] unless ref($args) eq 'ARRAY';

    $self->plugin->execute_plugin_hook( 'before_cart_add_validate', $self,
        $args );

    # basic validation + add each validated arg to @args

    foreach my $arg (@$args) {

        # make sure we have hasref
        unless ( ref($arg) eq 'HASH' ) {
            $arg = { sku => $arg };
        }

        die "Attempt to add product to cart without sku failed."
          unless defined $arg->{sku};

        my $result = $self->schema->resultset('Product')->find( $arg->{sku} );

        die "Product with sku '$arg->{sku}' does not exist."
          unless defined $result;

        my $product = {
            dbic_product  => $result,
            name          => $result->name,
            price         => $result->price,
            sku           => $result->sku,
            canonical_sku => $result->canonical_sku,
            uri           => $result->uri,
            weight        => $result->weight,
            quantity      => defined $arg->{quantity} ? $arg->{quantity} : 1,
            defined $arg->{extra} ? ( extra => $arg->{extra} ) : (),
        };

        if ( defined $arg->{combine} ) {
            $product->{combine} = $arg->{combine};
        }
        elsif ( $result->can('combine') ) {
            # the db product has combine attribute (not guaranteed if schema
            # is not IC6S)
            $product->{combine} = $result->combine;
        }
        else {
            $product->{combine} = 1;
        }

        push @products, $product;
    }

    $self->plugin->execute_plugin_hook( 'before_cart_add', $self, \@products );

    # add products to cart

    my $json = JSON::MaybeXS->new( pretty => 0, convert_blessed => 1 );

    foreach my $product ( @products ) {

        # bubble up the add
        my $ret = $orig->( $self, $product );

        # update or create in db taking notice of 'should_combine_by_sku'
 
        my $cart_product;
        if ( $ret->should_combine_by_sku ) {
            $cart_product = $self->dbic_cart_products->search(
                { 'me.sku' => $ret->sku, 'me.combine' => 1 },
                { rows     => 1 } )->single;
        }

        if ( $cart_product ) {
            $cart_product->update({ quantity => $ret->quantity });
        }
        else {
            $cart_product = $self->dbic_cart_products->create(
                {
                    sku           => $ret->sku,
                    quantity      => $ret->quantity,
                    cart_position => 0,
                    combine       => $ret->should_combine_by_sku,
                    extra         => $json->encode( $ret->extra ),
                }
            );
        }

        push @ret, $ret;
    }

    $self->plugin->execute_plugin_hook( 'after_cart_add', $self, \@ret );

    return wantarray ? @ret : \@ret;
};

=head2 clear

Removes all products from the cart.

=cut

around clear => sub {
    my ( $orig, $self ) = @_;

    $self->plugin->execute_plugin_hook( 'before_cart_clear', $self );

    $orig->( $self, @_ );

    # delete all products from this cart
    $self->dbic_cart_products->delete_all;

    $self->plugin->execute_plugin_hook( 'after_cart_clear', $self );

    return;
};

=head2 load_saved_products

Pulls old cart items into current cart - used after user login.

=cut

sub load_saved_products {
    my $self = shift;

    # should not be called unless user is logged in
    return unless $self->users_id;

    # find old carts and see if they have products we should move into
    # our new cart

    my $old_carts = $self->schema->resultset('Cart')->search(
        {
            'me.name'        => $self->name,
            'me.users_id'    => $self->users_id,
            'me.sessions_id' => [ undef, { '!=', $self->sessions_id } ],
        },
        {
            prefetch => 'cart_products',
        }
    );

    my $json = JSON::MaybeXS->new;

    while ( my $cart = $old_carts->next ) {

        my $cart_products = $cart->cart_products;
        while ( my $cart_product = $cart_products->next ) {

            $self->add(
                {
                    sku      => $cart_product->sku,
                    quantity => $cart_product->quantity,
                    combine  => $cart_product->combine,
                    $cart_product->extra
                    ? ( extra => $json->decode($cart_product->extra) )
                    : (),
                }
            );

        }
    }

    # delete the old carts (cascade deletes related cart products)
    $old_carts->delete;
}

=head2 remove

Remove single product from the cart. Takes SKU of product to identify
the product.

=cut

around remove => sub {
    my ( $orig, $self, $arg ) = @_;

    $self->plugin->execute_plugin_hook( 'before_cart_remove_validate', $self,
        $arg );

    my $index = $self->product_index( sub { $_->sku eq $arg } );

    die "Product sku not found in cart: $arg." unless $index >= 0;

    $self->plugin->execute_plugin_hook( 'before_cart_remove', $self, $arg );

    my $ret = $orig->( $self, $arg );

    $self->dbic_cart_products->search( { 'me.sku' => $ret->sku } )->delete;

    $self->plugin->execute_plugin_hook( 'after_cart_remove', $self, $arg );

    return $ret;
};

=head2 rename

Rename this cart. This is the writer method for L<Interchange6::Cart/name>.

Arguments: new name

Returns: new name

=cut

around rename => sub {
    my ( $orig, $self, $new_name ) = @_;

    my $old_name = $self->name;

    $self->plugin->execute_plugin_hook( 'before_cart_rename',
        $self, $old_name, $new_name );

    my $ret = $orig->( $self, $new_name );

    $self->dbic_cart->update( { name => $ret } );

    $self->plugin->execute_plugin_hook( 'after_cart_rename',
        $self, $old_name, $ret );

    return $ret;
};

sub _find_and_update {
    my ( $self, $sku, $new_product ) = @_;

    $self->dbic_cart_products->search(
        {
            'me.sku' => $sku
        }
    )->update($new_product);
}

=head2 set_sessions_id

Writer method for L<Interchange6::Cart/sessions_id>.

=cut

around set_sessions_id => sub {
    my ( $orig, $self, $arg ) = @_;

    $self->plugin->execute_plugin_hook( 'before_cart_set_sessions_id', $self,
        $arg );

    my $ret = $orig->( $self, $arg );

    $self->app->log( 'debug',
        "Change sessions_id of cart " . $self->id . " to: ", $arg );

    $self->dbic_cart->update({ sessions_id => $arg });

    $self->plugin->execute_plugin_hook( 'after_cart_set_sessions_id', $ret,
        $arg );

    return $ret;
};

=head2 set_users_id

Writer method for L<Interchange6::Cart/users_id>.

=cut

around set_users_id => sub {
    my ( $orig, $self, $arg ) = @_;

    $self->plugin->execute_plugin_hook( 'before_cart_set_users_id', $self,
        $arg );

    $self->app->log( 'debug',
        "Change users_id of cart " . $self->id . " to: $arg" );

    my $ret = $orig->( $self, $arg );

    $self->dbic_cart->update( { users_id => $arg } );

    $self->plugin->execute_plugin_hook( 'after_cart_set_users_id', $ret, $arg );

    return $ret;
};

=head2 update

Update quantity of products in the cart.

Parameters are pairs of SKUs and quantities, e.g.

  $cart->update(9780977920174 => 5,
                9780596004927 => 3);

Triggers before_cart_update and after_cart_update hooks.

A quantity of zero is equivalent to removing this product,
so in this case the remove hooks will be invoked instead
of the update hooks.

Returns updated products that are still in the cart. Products removed
via quantity 0 or products for which quantity has not changed will not
be returned.

=cut

around update => sub {
    my ( $orig, $self, @args ) = @_;
    my ( @products, $product, $new_product, $count );

  ARGS: while ( @args > 0 ) {

        my $sku = shift @args;
        my $qty = shift @args;

        die "Bad quantity argument to update: $qty" unless $qty =~ /^\d+$/;

        if ( $qty == 0 ) {

            # do remove instead of update
            $self->remove($sku);
            next ARGS;
        }

        $self->plugin->execute_plugin_hook( 'before_cart_update',
            $self, $sku, $qty );

        my ($ret) = $orig->( $self, $sku => $qty );

        $self->_find_and_update( $sku, { quantity => $qty } );

        $self->plugin->execute_plugin_hook( 'after_cart_update',
            $ret, $sku, $qty );
    }
};

=head1 HOOKS

The following hooks are available:

=over 4

=item before_cart_add_validate

Executed in L</add> before arguments are validated as being valid. Hook
receives the following arguments:

Receives: $cart, \%args

The args are those that were passed to L<add>.

Example:

    hook before_cart_add_validate => sub {
        my ( $cart, $args ) = @_;
        foreach my $arg ( @$args ) {
            my $sku = ref($arg) eq 'HASH' ? $arg->{sku} : $arg;
            die "bad product" if $sku eq "bad sku";
        }
    }

=item before_cart_add

Called in L</add> immediately before the products are added to the cart.

Receives: $cart, \@products

The products arrary ref contains simple hash references that will be passed
to L<Interchange6::Cart::Product/new>.

=item after_cart_add

Called in L</add> after products have been added to the cart.

Receives: $cart, \@products

The products arrary ref contains L<Interchange6::Cart::Product>s.

=item before_cart_remove_validate

Called at start of L</remove> before arg has been validated.

Receives: $cart, $sku

=item before_cart_remove

Called in L</remove> before validated product is removed from cart.

Receives: $cart, $sku

=item after_cart_remove

Called in L</remove> after product has been removed from cart.

Receives: $cart, $sku

=item before_cart_update

Executed for each pair of sku/quantity passed to L<update> before the update is performed.

Receives: $cart, $sku, $quantity

A quantity of zero is equivalent to removing this product,
so in this case the remove hooks will be invoked instead
of the update hooks.

=item after_cart_update

Executed for each pair of sku/quantity passed to L<update> after the update is performed.

Receives: $product, $sku, $quantity

Where C<$product> is the L<Interchange6::Cart::Product> returned from
L<Interchange6::Cart::Product/update>.

A quantity of zero is equivalent to removing this product,
so in this case the remove hooks will be invoked instead
of the update hooks.

=item before_cart_clear

Executed in L</clear> before the clear is performed.

Receives: $cart

=item after_cart_clear

Executed in L</clear> after the clear is performed.

Receives: $cart

=item before_cart_set_users_id

Executed in L<set_users_id> before users_id is updated.

Receives: $cart, $userid

=item after_cart_set_users_id

Executed in L<set_users_id> after users_id is updated.

Receives: $new_usersid, $requested_userid

=item before_cart_set_sessions_id

Executed in L<set_sessions_id> before sessions_id is updated.

Receives: $cart, $sessionid

=item after_cart_set_sessions_id

Executed in L<set_sessions_id> after sessions_id is updated.

Receives: $cart, $sessionid

=item before_cart_rename

Executed in L</rename> before cart L<Interchange6::Cart/name> is updated.

Receives: $cart, $old_name, $new_name

=item after_cart_rename

Executed in L</rename> after cart L<Interchange6::Cart/name> is updated.

Receives: $cart, $old_name, $new_name

=back

=head1 AUTHORS

 Stefan Hornburg (Racke), <racke@linuxia.de>
 Peter Mottram (SysPete), <peter@sysnix.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2011-2016 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
