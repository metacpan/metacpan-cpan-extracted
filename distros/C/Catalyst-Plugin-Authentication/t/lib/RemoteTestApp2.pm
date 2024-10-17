package RemoteTestApp2;
use strict;
use warnings;

use Catalyst qw/
   Authentication
/;
use Moose;
extends 'Catalyst';
with 'RemoteTestData';

__PACKAGE__->config(
    'Plugin::Authentication' => {
        default_realm => 'remote',
        realms => {
            remote => {
                credential => {
                    class => 'Remote',
                    allow_regexp => '^(bob|john|CN=.*)$',
                    deny_regexp=> 'denied',
                    cutname_regexp=> 'CN=(.*)/OU=Test',
                    source => 'SSL_CLIENT_S_DN',
                    username_field => 'my_user_name',
                },
                store => {
                    class => 'Null',
                },
            },
        },
    },
);
__PACKAGE__->setup;

1;
