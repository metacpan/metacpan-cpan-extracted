package Dancer2::Plugin::Interchange6;

use strict;
use warnings;

use Dancer2::Plugin;
use Dancer2::Plugin::Interchange6::Business::OnlinePayment;
use Module::Runtime 'use_module';
use Scalar::Util 'weaken';

=head1 NAME

Dancer2::Plugin::Interchange6 - Interchange6 Shop Plugin for Dancer2

=head1 VERSION

Version 0.203

=cut

our $VERSION = '0.203';

=head1 REQUIREMENTS

All Interchange6 Dancer2 applications need to use the L<Dancer2::Session::DBIC>
engine.

The easiest way to configure this is in your C<config.yml> (or whatever other
configuration file you prefer):

  plugins
    DBIC:
      default:
        schema_class: Interchange6::Schema
        # ... other DBIC plugin config here
  engines:
    session:
      DBIC:
        db_connection_name: default # connection name from DBIC plugin
  session: DBIC

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
Defaults to L<Dancer2::Plugin::Interchange6::Cart>.

=item * carts_var_name

The plugin caches carts in a L<Dancer2/var> and the name of the var used can
be set via C<carts_var_name>. Defaults to C<ic6_carts>.

=back

=head1 ROUTES

You can use the L<Dancer2::Plugin::Interchange6::Routes> plugin bundled with this
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

    use Dancer2;
    use Dancer2::Plugin::Interchange6;
    use Dancer2::Plugin::Interchange6::Routes;

    get '/shop' => sub {
        ...
    };

    ...

    shop_setup_routes;

    true;

Please refer to L<Dancer2::Plugin::Interchange6::Routes> for configuration
options and further information.

=head1 KEYWORDS

=head2 shop_cart

Returns L<Dancer2::Plugin::Interchange6::Cart> object.


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

Available accessors are:

=over

=item C<shop_address>

=item C<shop_attribute>

=item C<shop_country>

=item C<shop_message>

=item C<shop_navigation>

=item C<shop_order>

=item C<shop_product>

=item C<shop_state>

=item C<shop_user>

=back

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
functionality please copy/link to Dancer2 App/bin directory.

    interchange6-expire-sessions

=cut

# config

has cart_class => (
    is          => 'ro',
    from_config => sub { 'Dancer2::Plugin::Interchange6::Cart' },
);

has carts_var_name => (
    is => 'ro',
    from_config => sub { 'ic6_carts' },
);

# plugins we use

has plugin_auth_extensible => (
    is      => 'ro',
    is      => 'lazy',
    default => sub {
        $_[0]->app->with_plugin('Dancer2::Plugin::Auth::Extensible');
    },
    handles  => ['logged_in_user'],
    init_arg => undef,
);

has plugin_dbic => (
    is      => 'ro',
    is      => 'lazy',
    default => sub {
        $_[0]->app->with_plugin('Dancer2::Plugin::DBIC');
    },
    handles  => [ 'resultset', 'schema' ],
    init_arg => undef,
);

# hooks

plugin_hooks(
    qw/before_cart_add_validate
      before_cart_add after_cart_add
      before_cart_update after_cart_update
      before_cart_remove_validate
      before_cart_remove after_cart_remove
      before_cart_rename after_cart_rename
      before_cart_clear after_cart_clear
      before_cart_set_users_id after_cart_set_users_id
      before_cart_set_sessions_id after_cart_set_sessions_id
      before_cart_display
      before_checkout_display
      before_login_display
      /
);

plugin_keywords 'shop_address',
  'shop_attribute',
  [ 'shop_cart', 'cart' ],
  'shop_charge',
  'shop_country',
  'shop_message',
  'shop_navigation',
  'shop_order',
  'shop_product',
  'shop_redirect',
  'shop_schema',
  'shop_state',
  'shop_user';

sub BUILD {
    my $plugin = shift;
    weaken ( my $weak_plugin = $plugin );
    $plugin->app->add_hook(
        Dancer2::Core::Hook->new(
            name => 'before',
            code => sub {
                # D2PAE::Provider::DBIC returns logged_in_user as hashref
                # instead of a proper user result so we have to mess about.
                # At some point in the future D2PAE will be fixed to allow
                # user objects to be returned.
                my $user = $weak_plugin->logged_in_user || undef;
                if ( $user ) {
                    $user = $weak_plugin->shop_user->find(
                        {
                            username => $user->{username}
                        }
                    );
                }
                $weak_plugin->shop_schema->set_current_user($user);
            },
        )
    );
}

sub shop_address {
    shift->_shop_resultset( 'Address', @_ );
}

sub shop_attribute {
    shift->_shop_resultset( 'Attribute', @_ );
}

sub shop_cart {
    my $plugin = shift;

    my %args;

    # cart name from arg or default 'main'
    $args{name} = @_ == 1 ? $_[0] : 'main';

    # set name of var we will stash carts in
    my $var = $plugin->carts_var_name;
    $plugin->app->log( "debug", "carts_var_name: $var" );

    my $carts = $plugin->app->request->var($var) || {};

    if ( !defined $carts->{ $args{name} } ) {

        # can't find this cart in stash

        $args{plugin}      = $plugin;
        $args{schema}      = $plugin->schema;
        $args{sessions_id} = $plugin->app->session->id;

        if ( my $user_ref = $plugin->logged_in_user ) {

            # user is logged in
            # FIXME: D2PAE currently returns a hashref
            $args{users_id} = $user_ref->{users_id};
        }

        $carts->{ $args{name} } = use_module($plugin->cart_class)->new(%args);
    }

    # stash carts back in var
    $plugin->app->request->var( $var => $carts );

    return $carts->{ $args{name} };
}

sub shop_charge {
    my ( $plugin, %args ) = @_;
    my ( $schema, $bop_object, $payment_settings, $provider,
        $provider_settings );

    $payment_settings = $plugin->config->{payment};

    die "No payment setting" unless $payment_settings;

    # determine payment provider
    if ( $args{provider} ) {
        $provider = $args{provider};
    }
    else {
        $provider = $payment_settings->{default_provider};
    }

    if ( exists $payment_settings->{providers}->{$provider} ) {
        $provider_settings = $payment_settings->{providers}->{$provider};
    }
    else {
        die "Settings for provider $provider missing.";
    }

    my %payment_data = (
        payment_mode   => $provider,
        status         => 'request',
        sessions_id    => $plugin->app->session->id,
        payment_action => 'charge',
        amount         => $args{amount},
        users_id       => $plugin->app->session->read('logged_in_user_id'),
    );

    # create payment order
    $schema = $plugin->shop_schema;

    my $payment_order =
      $schema->resultset('PaymentOrder')->create( \%payment_data );

    # create BOP object wrapper with provider settings
    $bop_object =
      Dancer2::Plugin::Interchange6::Business::OnlinePayment->new( $provider,
        %$provider_settings );

    $bop_object->payment_order($payment_order);

    # call charge method
    $bop_object->charge(%args);

    if ( $bop_object->is_success ) {
        $payment_order->update(
            {
                status    => 'success',
                auth_code => $bop_object->authorization,
            }
        );
    }
    else {
        $payment_order->update(
            {
                status                => 'failure',
                payment_error_code    => $bop_object->error_code,
                payment_error_message => $bop_object->error_message,
            }
        );
    }

    return $bop_object;
}

sub shop_country {
    shift->_shop_resultset( 'Country', @_ );
}

sub shop_message {
    shift->_shop_resultset( 'Message', @_ );
}

sub shop_navigation {
    shift->_shop_resultset( 'Navigation', @_ );
}

sub shop_order {
    shift->_shop_resultset( 'Order', @_ );
}

sub shop_product {
    shift->_shop_resultset( 'Product', @_ );
}

sub shop_redirect {
    return $_[0]->resultset('UriRedirect')->redirect( $_[1] );
}

sub shop_schema {
    my $plugin = shift;
    my $schema_key;

    if (@_) {
        $schema_key = $_[0];
    }
    else {
        $schema_key = 'default';
    }

    return $plugin->schema($schema_key);
}

sub shop_state {
    shift->_shop_resultset( 'State', @_ );
}

sub shop_user {
    shift->_shop_resultset( 'User', @_ );
}

sub _shop_resultset {
    my $plugin = shift;
    my ( $name, $key ) = @_;

    if ( defined $key ) {
        return $plugin->resultset($name)->find($key);
    }

    return $plugin->resultset($name);
}

=head1 ACKNOWLEDGEMENTS

The L<Dancer2> developers and community for their great application framework
and for their quick and competent support.

Peter Mottram for his patches and conversion of this plugin to Dancer2.

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2016 Stefan Hornburg (Racke).

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 SEE ALSO

L<Interchange6>, L<Interchange6::Schema>

=cut

1;
