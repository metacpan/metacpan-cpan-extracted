package AuthRealmTestAppProgressive;
use warnings;
use strict;
use base qw/Catalyst/;

### using A::Store::minimal with new style realms
### makes the app blow up, since c::p::a::s::minimal
### isa c:a::s::minimal, and it's compat setup() gets
### run, with an unexpected config has (realms on top,
### not users). This tests makes sure the app no longer
### blows up when this happens.
use Catalyst qw/
    Authentication
    Authentication::Store::Minimal
/;

our %members = (
    'members' => {
        bob => { password => "s00p3r" }
    },
    'other' => {
        sally => { password => "s00p3r" }
    },
);

__PACKAGE__->config('Plugin::Authentication' => {
    default_realm => 'progressive',
    progressive => {
        class  => 'Progressive',
        realms => [ 'other', 'members' ],
    },
    other => {
        credential => {
            class => 'Password',
            password_field => 'password',
            password_type  => 'clear'
        },
        store => {
            class => 'Minimal',
            users => $members{other},
        }
    },
    members => {
        credential => {
            class => 'Password',
            password_field => 'password',
            password_type => 'clear'
        },
        store => {
            class => 'Minimal',
            users => $members{members},
        }
    },
});

__PACKAGE__->setup;

1;

