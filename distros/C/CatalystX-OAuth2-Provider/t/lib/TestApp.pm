package TestApp;
use Moose;
use namespace::autoclean;

use Catalyst qw/
    +CatalystX::OAuth2::Provider
    Authentication
    Session
    Session::Store::FastMmap
    Session::State::Cookie
    Session::State::URI
    Session::State::Auth
/;
extends 'Catalyst';

__PACKAGE__->config(home => undef, root => undef);

__PACKAGE__->config(
    'Plugin::Authentication' => {
        default => {
            credential => {
                class => 'Password',
                password_field => 'password',
                password_type => 'clear'
            },
            store => {
                class => 'Minimal',
                users => {
                    di => {
                        password => "r0ck3r",
                    },
                },
            },
        },
    },
);

__PACKAGE__->config(
    'Controller::OAuth' => {
        login_form => {
           template => 'user/login.tt',
           field_names => {
               username => 'mail',
               password => 'userPassword'
           }
        },
        authorize_form => {
            template => 'oauth/authorize.tt',
        },
        auth_info => {
            client_1 => {
                client_id      => q{36d24a484e8782decbf82a46459220a10518239e},
                client_secret  => q{947da6393f802a7abe4ecf17ff12cc3f10704ee4},
                redirect_uri   => q{http://localhost.client:3333/callback},
            },
            client_2 => {
                client_id      => q{36d24a484e8782decbf82a46459220a10518239e},
                client_secret  => q{947da6393f802a7abe4ecf17ff12cc3f10704ee4},
                redirect_uri   => q{http://localhost.client:3333/callback},
            }
        },
        protected_resource => {
           secret_key => 'secret',
        }
    },
    'Plugin::Session' => { param => 'code', rewrite_body => 0 }, #Handle authorization code
);

__PACKAGE__->setup;

1;
