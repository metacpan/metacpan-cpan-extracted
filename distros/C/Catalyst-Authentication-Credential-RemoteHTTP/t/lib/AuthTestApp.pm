package AuthTestApp;
use warnings;
use strict;

use Catalyst qw/
    Authentication
    /;

# this info needs to match that in TestWebServer
our $members = {
    insecure => { password => '123456' },                 # more secure than SpaceBalls
    paranoid => { password => 'very_secure_password!' }
};

__PACKAGE__->config(
    'Plugin::Authentication' => {
        default_realm => 'members',
        realms        => {
            members => {
                credential => {
                    class => 'RemoteHTTP',
                    url   => 'http://127.0.0.1:10763/stuff.html',
                },
                store => {
                    class => 'Minimal',
                    users => $members
                }
            },
        }
    }
);

__PACKAGE__->setup;
