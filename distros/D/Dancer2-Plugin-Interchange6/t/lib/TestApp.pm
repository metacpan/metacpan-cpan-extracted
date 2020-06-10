package TestApp;

use strict;
use warnings;

BEGIN {
    $ENV{DANCER_CONFDIR} = 't';
    $ENV{DANCER_ENVDIR}  = 't/environment';
    $ENV{DANCER_VIEWS}   = 't/views';
    die "DANCER_ENVIRONMENT not set" unless $ENV{DANCER_ENVIRONMENT};
}

{

    package Fixtures;
    use Moo;
    with 'Interchange6::Test::Role::Fixtures';
    has ic6s_schema => ( is => 'ro', );
}

use Dancer2;
use Dancer2::Plugin::Interchange6;
use Dancer2::Plugin::Interchange6::Routes;
use Dancer2::Plugin::DBIC;
use Dancer2::Plugin::Auth::Extensible;

# ROUTES

get '/' => sub {
    return 'Home page';
};

get '/login/denied' => sub {
    return 'Denied';
};

get '/private' => require_login sub {
    return 'Private page';
};

get '/sessionid' => sub {
    return session->id;
};

post '/rename_cart' => sub {
    shop_cart->rename( param('name') );
};

get '/clear_cart' => sub {
    shop_cart->clear;
};

post '/set_cart_sessions_id' => sub {
    shop_cart->set_sessions_id( param('id') );
};

get '/current_user' => sub {
    if ( my $user = shop_schema->current_user ) {
        return $user->name;
    }
    else {
        return 'undef';
    }
};

post '/shop_charge' => sub {
    my %params = params;
    my $charge = shop_charge(%params);
    return join( ',',
        $charge->is_success,
        $charge->authorization,
        $charge->order_number,
        ref( $charge->payment_order ),
        $charge->payment_order->in_storage,
        $charge->payment_order->status,
    );
};

post '/cart_test' => sub {
    my $name = body_parameters->get('name');
    my $cart;
    if ($name) {
        shop_cart($name);    # so next call is from stash in Dancer2 var
        $cart = shop_cart($name);
    }
    else {
        shop_cart;
        $cart = shop_cart;
    }
    return join( ',', ref($cart), $cart->name );
};

shop_setup_routes;

# HOOKS

# display hooks

hook before_cart_display => sub {
    my $tokens        = shift;
    my $products      = $tokens->{cart};
    my $cart_error    = $tokens->{cart_error};
    my $cart_subtotal = $tokens->{cart_subtotal};
    my $cart_total    = $tokens->{cart_total};

    debug join( " ",
        "hook before_cart_display",
        scalar @$products,
        sprintf( "%.2f", $cart_subtotal ),
        sprintf( "%.2f", $cart_total ) );

    $tokens->{cart} = join(
        ",",
        sort map {
            join( ':',
                $_->sku, $_->name, $_->quantity,
                sprintf( "%.2f", $_->price ),
                sprintf( "%.2f", $_->selling_price ), $_->uri )
        } @$products
    );
};

hook before_checkout_display => sub {
    my $tokens        = shift;
    my $products      = $tokens->{cart};
    my $cart_subtotal = $tokens->{cart_subtotal};
    my $cart_total    = $tokens->{cart_total};

    debug join( " ",
        "hook before_checkout_display",
        scalar @$products,
        sprintf( "%.2f", $cart_subtotal ),
        sprintf( "%.2f", $cart_total ) );

    $tokens->{cart} = join(
        ",",
        sort map {
            join( ':',
                $_->sku, $_->name, $_->quantity,
                sprintf( "%.2f", $_->price ),
                sprintf( "%.2f", $_->selling_price ), $_->uri )
        } @$products
    );
};

hook before_login_display => sub {
    my ($tokens) = @_;
    my $error      = $tokens->{error}      || 'none';
    my $return_url = $tokens->{return_url} || 'none';

    debug join( " ", "hook before_login_display", $error, $return_url );
};

hook before_product_display => sub {
    my $tokens  = shift;
    my $product = $tokens->{product};

    debug join( " ",
        "hook before_product_display",
        $product->sku, $product->name, sprintf( "%.2f", $product->price ) );

    $tokens->{name} = $product->name;
};

hook before_navigation_search => sub {
    my ($tokens) = @_;
    my $nav      = $tokens->{navigation};
    my $page     = $tokens->{page};
    my $template = $tokens->{template};

    debug
      join( " ", "hook before_navigation_search", $nav->name, $page,
        $template );
};

hook before_navigation_display => sub {
    my $tokens   = shift;
    my $nav      = $tokens->{navigation};
    my $page     = $tokens->{page};
    my $pager    = $tokens->{pager};
    my $products = $tokens->{products};
    my $template = $tokens->{template};

    debug join( " ",
        "hook before_navigation_display",
        $nav->name, $page, $pager->last_page, scalar @$products, $template );

    $tokens->{name} = $nav->name;
    $tokens->{products} = join( ",", sort map { $_->name } @$products );
};

# cart hooks

hook before_cart_add_validate => sub {
    my ( $cart, $args ) = @_;

    debug join( " ",
        "hook before_cart_add_validate",
        $cart->name,
        sprintf( "%.2f", $cart->total ),
        ref( $args->[0] ) eq 'HASH' ? $args->[0]->{sku} : $args->[0] );
};

hook before_cart_add => sub {
    my ( $cart, $products ) = @_;

    debug join( " ",
        "hook before_cart_add",
        $cart->name,
        sprintf( "%.2f", $cart->total ),
        $products->[0]->{sku},
        $products->[0]->{name} );
};

hook after_cart_add => sub {
    my ( $cart, $products ) = @_;

    debug join( " ",
        "hook after_cart_add",
        $cart->name,
        sprintf( "%.2f", $cart->total ),
        ref( $products->[0] ),
        $products->[0]->sku,
        $products->[0]->name );
};

hook before_cart_update => sub {
    my ( $cart, $sku, $quantity ) = @_;

    $quantity = 'undef' if !defined $quantity;
    $sku      = 'undef' if !defined $sku;

    debug join( " ",
        "hook before_cart_update",
        $cart->name, sprintf( "%.2f", $cart->total ),
        $sku, $quantity );
};

hook after_cart_update => sub {
    my ( $ret, $sku, $quantity ) = @_;

    debug join( " ",
        "hook after_cart_update",
        $ret->sku, $ret->quantity, $sku, $quantity );
};

hook before_cart_remove_validate => sub {
    my ( $cart, $sku ) = @_;

    debug join( " ",
        "hook before_cart_remove_validate",
        $cart->name,
        sprintf( "%.2f", $cart->total ),
        $sku || 'undef' );
};

hook before_cart_remove => sub {
    my ( $cart, $sku ) = @_;

    debug join( " ",
        "hook before_cart_remove",
        $cart->name,
        sprintf( "%.2f", $cart->total ),
        $sku || 'undef' );
};

hook after_cart_remove => sub {
    my ( $cart, $sku ) = @_;

    debug join( " ",
        "hook after_cart_remove", $cart->name,
        sprintf( "%.2f", $cart->total ), $sku );
};

hook before_cart_rename => sub {
    my ( $cart, $old_name, $new_name ) = @_;

    debug join( " ",
        "hook before_cart_rename",
        $cart->name,
        $old_name || 'undef',
        $new_name || 'undef' );
};

hook after_cart_rename => sub {
    my ( $cart, $old_name, $new_name ) = @_;

    debug
      join( " ", "hook after_cart_rename", $cart->name, $old_name, $new_name );
};

hook before_cart_clear => sub {
    my ($cart) = @_;

    debug join( " ",
        "hook before_cart_clear",
        $cart->name, sprintf( "%.2f", $cart->total ) );
};

hook after_cart_clear => sub {
    my ($cart) = @_;

    debug join( " ",
        "hook after_cart_clear",
        $cart->name, sprintf( "%.2f", $cart->total ) );
};

hook before_cart_set_users_id => sub {
    my ( $cart, $users_id ) = @_;

    debug join( " ",
        "hook before_cart_set_users_id",
        $cart->name,
        sprintf( "%.2f", $cart->total ),
        $cart->users_id || 'undef',
        $users_id || 'undef' );
};

hook after_cart_set_users_id => sub {

    debug join( " ", "hook after_cart_set_users_id", @_ );
};

hook before_cart_set_sessions_id => sub {
    my ( $cart, $sessions_id ) = @_;

    debug join( " ",
        "hook before_cart_set_sessions_id",
        $cart->name,
        sprintf( "%.2f", $cart->total ),
        $cart->sessions_id || 'undef',
        $sessions_id || 'undef' );
};

hook after_cart_set_sessions_id => sub {

    debug join( " ", "hook after_cart_set_sessions_id", @_ );
};

1;
