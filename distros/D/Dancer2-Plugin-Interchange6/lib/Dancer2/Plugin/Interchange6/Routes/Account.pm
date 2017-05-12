package Dancer2::Plugin::Interchange6::Routes::Account;

use strict;
use warnings;

use Try::Tiny;

=head1 NAME

Dancer2::Plugin::Interchange6::Routes::Account - Account routes for Interchange6 Shop Machine

=head1 DESCRIPTION

The Interchange6 account routes module installs Dancer2 routes for
login and logout

=cut

=head1 FUNCTIONS

=head2 account_routes

Returns the account routes based on the plugin configuration.

=cut

sub account_routes {
    my $plugin = shift;
    my %routes;

    $routes{login}->{get} = sub {
        my $app   = shift;
        my $d2pae = $app->with_plugin('Dancer2::Plugin::Auth::Extensible');
        return $app->redirect('/') if $d2pae->logged_in_user;

        my %values;

        if ( $app->request->param('login_failed') ) {
            $values{error} = "Login failed";
        }

        # record return_url in template tokens
        if ( my $return_url = $app->request->param('return_url') ) {
            $values{return_url} = $return_url;
        }

        # call before_login_display route so template tokens
        # can be injected
        $app->execute_hook( 'plugin.interchange6.before_login_display',
            \%values );

        # record return_url in the session to reuse it in post route
        $app->session->write( return_url => $values{return_url} );

        $app->template( $plugin->login_template, \%values );
    };

    $routes{login}->{post} = sub {
        my $app    = shift;
        my $d2pae  = $app->with_plugin('Dancer2::Plugin::Auth::Extensible');
        my $d2pic6 = $app->with_plugin('Dancer2::Plugin::Interchange6');

        return $app->redirect('/') if $d2pae->logged_in_user;

        my $login_route = '/' . $plugin->login_uri;

        my $user = $d2pic6->shop_user->find(
            { username => $app->request->params->{username} } );

        my ( $success, $realm, $current_cart );

        if ($user) {

            # remember current cart object
            $current_cart = $d2pic6->shop_cart;

            ( $success, $realm ) = $d2pae->authenticate_user(
                $app->request->params->{username},
                $app->request->params->{password}
            );
        }

        if ($success) {
            $app->session->write( logged_in_user       => $user->username );
            $app->session->write( logged_in_user_id    => $user->id );
            $app->session->write( logged_in_user_realm => $realm );

            if ( !$current_cart->users_id ) {
                $current_cart->set_users_id( $user->id );
            }

            # now pull back in old cart items from previous authenticated
            # sessions were sessions_id is undef in db cart
            $current_cart->load_saved_products;

            if ( $app->session->read('return_url') ) {
                my $url = $app->session->read('return_url');
                $app->session->write( return_url => undef );
                return $app->redirect($url);
            }
            else {
                return $app->redirect( '/' . $plugin->login_success_uri );
            }
        }
        else {
            $app->log(
                "debug",
                "Authentication failed for ",
                $app->request->params->{username}
            );

            return $app->forward(
                $login_route,
                {
                    return_url   => $app->request->params->{return_url},
                    login_failed => 1
                },
                { method => 'get' }
            );
        }
    };

    $routes{logout}->{any} = sub {
        my $app    = shift;
        my $d2pic6 = $app->with_plugin('Dancer2::Plugin::Interchange6');
        my $cart   = $d2pic6->shop_cart;
        if ( $cart->count > 0 ) {

            # save our items for next login
            try {
                $cart->set_sessions_id(undef);
            }
            catch {
                $app->log( "warning",
                    "Failed to set sessions_id to undef for cart id: ",
                    $cart->id );
            };
        }

        # any empty cart with sessions_id matching our session id will be
        # destroyed here
        $app->destroy_session;
        return $app->redirect('/');
    };

    return \%routes;
}

1;
