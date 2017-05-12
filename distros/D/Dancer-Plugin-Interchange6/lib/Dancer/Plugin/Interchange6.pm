package Dancer::Plugin::Interchange6;

use strict;
use warnings;

use Dancer qw(:syntax !before !after);
use Dancer::Plugin;
use Dancer::Plugin::DBIC;
use Dancer::Plugin::Auth::Extensible;

use Dancer::Plugin::Interchange6::Cart;
use Dancer::Plugin::Interchange6::Business::OnlinePayment;

use Module::Runtime 'use_module';

=head1 NAME

Dancer::Plugin::Interchange6 - Interchange6 Shop Plugin for Dancer

=head1 VERSION

Version 0.121

=cut

our $VERSION = '0.121';

=head1 DESCRIPTION

This L<Dancer> plugin is now DEPRECATED since all new development has moved
to the L<Dancer2> plugin L<Dancer2::Plugin::Interchange6>.

=head1 REQUIREMENTS

All Interchange6 Dancer applications need to use the L<Dancer::Session::DBIC>
engine.

The easiest way to configure this is in your main module, just after all
the C<use> statements:

   set session => 'DBIC';
   set session_options => {schema => schema};

=head1 CONFIGURATION

Available configuration options:

  plugins:
    Interchange6:
      cart_class: MyApp::Cart
      carts_var_name: some_other_var

=over

=item * cart_class

If you wish to subclass the cart you can have L</shop_cart> return your
subclassed cart instead. You set the cart class via C<cart_class>.
Defaults to L<Dancer::Plugin::Interchange6::Cart>.

=item * carts_var_name

The plugin caches carts in a L<Dancer/var> and the name of the var used can
be set via C<carts_var_name>. Defaults to C<ic6_carts>.

=back

=head1 ROUTES

You can use the L<Dancer::Plugin::Interchange6::Routes> plugin bundled with this
plugin to setup standard routes for:

=over 4

=item product listing

=item product display

=item cart display

=item checkout form

=back

To enable these routes, you put the C<shop_setup_routes> keyword at the end
of your main module:

    package MyShop;

    use Dancer ':syntax';
    use Dancer::Plugin::Interchange6;
    use Dancer::Plugin::Interchange6::Routes;

    get '/shop' => sub {
        ...
    };

    ...

    shop_setup_routes;

    true;

Please refer to L<Dancer::Plugin::Interchange6::Routes> for configuration options
and further information.

=head1 KEYWORDS

=head2 shop_cart

Returns L<Dancer::Plugin::Interchange6::Cart> object.


=head2 shop_charge

Creates payment order and authorizes amount.

=head2 shop_redirect

Calls L<Interchange6::Schema::ResultSet::UriRedirect/redirect> with given args.

=head2 shop_schema

Returns L<Interchange6::Schema> object.

=head2 shop_...

Accessors for L<Interchange6::Schema> result classes. You can use it
to retrieve a single object or the corresponding result set.

    shop_product('F0001')->uri;

    shop_navigation->search({type => 'manufacturer',
                             active => 1});

Available accessors are C<shop_address>, C<shop_attribute>, C<shop_country>,
C<shop_message>, C<shop_navigation>, C<shop_order>, C<shop_product>,
C<shop_state> and C<shop_user>.

=head1 HOOKS

This plugin installs the following hooks:

=head2 Add to cart

The functions registered for these hooks receive the cart object
and the item to be added as parameters.

=over 4

=item before_cart_add_validate

Triggered before item is validated for adding to the cart.

=item before_cart_add

Triggered before item is added to the cart.

=item after_cart_add

Triggered after item is added to the cart.
Used by DBI backend to save item to the database.

=back

=head2 Update cart

The functions registered for these hooks receive the cart object,
the current item in the cart and the updated item.

=over 4

=item before_cart_update

Triggered before cart item is updated (changing quantity).

=item after_cart_update

Triggered after cart item is updated (changing quantity).
Used by DBI backend to update item to the database.

=back

=head2 Remove from cart

The functions registered for these hooks receive the cart object
and the item to be added as parameters.

=over 4

=item before_cart_remove_validate

Triggered before item is validated for removal.
Receives cart object and item SKU.

=item before_cart_remove

Triggered before item is removed from the cart.
Receives cart object and item.

=item after_cart_remove

Triggered after item is removed from the cart.
Used by DBI backend to delete item from the database.
Receives cart object and item.

=back

=head2 Clear cart

=over 4

=item before_cart_clear

Triggered before cart is cleared.

=item after_cart_clear

Triggered after cart is cleared.

=back

=head2 Rename cart

The functions registered for these hooks receive the cart object,
the old name and the new name.

=over 4

=item before_cart_rename

Triggered before cart is renamed.

=item after_cart_rename

Triggered after cart is renamed.

=item before_cart_set_users_id

Triggered before users_id is set for the cart.

=item after_cart_set_users_id

Triggered after users_id is set for the cart.

=item before_cart_set_sessions_id

Triggered before sessions_id is set for the cart.

=item after_cart_set_sessions_id

Triggered after sessions_id is set for the cart.

=back

=head1 EXPIRE DBIC SESSIONS

This command expires/manages DBIC sessions and carts.  NOTE: For proper
functionality please copy/link to Dancer App/bin directory.

    interchange6-expire-sessions

=cut

register_hook(qw/before_cart_add_validate
                 before_cart_add after_cart_add
                 before_cart_update after_cart_update
                 before_cart_remove_validate
                 before_cart_remove after_cart_remove
                 before_cart_rename after_cart_rename
                 before_cart_clear after_cart_clear
                 before_cart_set_users_id after_cart_set_users_id
                 before_cart_set_sessions_id after_cart_set_sessions_id
                /);

register shop_schema => sub {
    _shop_schema(@_);
};

register shop_address => sub {
    _shop_resultset('Address', @_);
};

register shop_attribute => sub {
    _shop_resultset('Attribute', @_);
};

register shop_country => sub {
    _shop_resultset('Country', @_);
};

register shop_message => sub {
    _shop_resultset('Message', @_);
};

register shop_navigation => sub {
    _shop_resultset('Navigation', @_);
};

register shop_order => sub {
    _shop_resultset('Order', @_);
};

register shop_product => sub {
    _shop_resultset('Product', @_);
};

register shop_state => sub {
    _shop_resultset('State', @_);
};

register shop_redirect => sub {
    return resultset('UriRedirect')->redirect($_[0]);
};

register shop_user => sub {
    _shop_resultset('User', @_);
};

register shop_charge => sub {
	my (%args) = @_;
	my ($schema, $bop_object, $payment_settings, $provider, $provider_settings);

	$payment_settings = plugin_setting->{payment};

    die "No payment setting" unless $payment_settings;

    # determine payment provider
    if ( $args{provider} ) {
        $provider = $args{provider};
    }
    else {
        $provider = $payment_settings->{default_provider};
    }

    if (exists $payment_settings->{providers}->{$provider}) {
        $provider_settings = $payment_settings->{providers}->{$provider};
    }
    else {
        die "Settings for provider $provider missing.";
    }

    my %payment_data = (payment_mode => $provider,
                        status => 'request',
                        sessions_id => session->id,
                        payment_action => 'charge',
                        amount => $args{amount},
                        users_id => session('logged_in_user_id'),
                        );

    # create payment order
    $schema = _shop_schema();

    my $payment_order = $schema->resultset('PaymentOrder')->create(\%payment_data);

    # create BOP object wrapper with provider settings
	$bop_object = Dancer::Plugin::Interchange6::Business::OnlinePayment->new($provider, %$provider_settings);

    $bop_object->payment_order($payment_order);

    # call charge method
    $bop_object->charge(%args);

    if ($bop_object->is_success) {
        $payment_order->update({
            status => 'success',
            auth_code => $bop_object->authorization,
        });
    }
    else {
        $payment_order->update({
            status => 'failure',
	    payment_error_code => $bop_object->error_code,
	    payment_error_message => $bop_object->error_message,
        });
    }

	return $bop_object;
};

register cart => \&_shop_cart;
register shop_cart => \&_shop_cart;

sub _shop_cart {

    my ( %args, $user_ref );

    # cart name from arg or default 'main'
    $args{name} = @_ == 1 ? $_[0] : 'main';

    # set name of var we will stash carts in
	my $var = plugin_setting->{carts_var_name} || 'ic6_carts';
    debug "carts_var_name: $var";

    # cart class
    my $cart_class = plugin_setting->{cart_class}
      || 'Dancer::Plugin::Interchange6::Cart';

    my $carts = var($var) || {};

    if ( !defined $carts->{ $args{name} } ) {

        # can't find this cart in stash

        $args{sessions_id} = session->id;

        if ( $user_ref = logged_in_user ) {

            # user is logged in
            $args{users_id} = $user_ref->users_id;
        }

        $carts->{ $args{name} } = use_module($cart_class)->new(%args);
    }

    # stash carts back in var
    var $var => $carts;

    return $carts->{ $args{name} };
}

sub _shop_schema {
    my $schema_key;

    if (@_) {
        $schema_key = $_[0];
    }
    else {
        $schema_key = 'default';
    }

    return schema($schema_key);
};

sub _shop_resultset {
    my ($name, $key) = @_;

    if (defined $key) {
        return resultset($name)->find($key);
    }

    return resultset($name);
};

register_plugin;

=head1 ACKNOWLEDGEMENTS

The L<Dancer> developers and community for their great application framework
and for their quick and competent support.

Peter Mottram for his patches.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2016 Stefan Hornburg (Racke).

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 SEE ALSO

L<Dancer2::Plugin::Interchange6>

L<Interchange6>, L<Interchange6::Schema>

=cut

1;
