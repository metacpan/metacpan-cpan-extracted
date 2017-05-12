package AuthRealmTestApp;
use warnings;
use strict;

use Catalyst qw/
    Authentication
    Authentication::Store::Minimal
/;

use Test::More;
use Test::Exception;

our $members = {
    bob => {
        password => "s00p3r"
    },
    william => {
        password => "s3cr3t"
    }
};

our $admins = {
    joe => {
        password => "31337"
    }
};

__PACKAGE__->config('Plugin::Authentication' => {
    default_realm => 'members',
    realms => {
        members => {
            credential => {
                class => 'Password',
                password_field => 'password',
                password_type => 'clear'
            },
            store => {
                class => 'Minimal',
                users => $members
            }
        },
        admins => {
            credential => {
                class => 'Password',
                password_field => 'password',
                password_type => 'clear'
            },
            store => {
                class => 'Minimal',
                users => $admins
            }
        }
    }
});

__PACKAGE__->setup;

1;

