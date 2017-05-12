package RemoteTestApp2;
use strict;
use warnings;

use Catalyst qw/
   Authentication
/;

use base qw/Catalyst/;
unless ($Catalyst::VERSION >= 5.89000) {
    __PACKAGE__->engine_class('RemoteTestEngine');
}
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
if ($Catalyst::VERSION >= 5.89000) {
    require RemoteTestEngineRole;
    RemoteTestEngineRole->meta->apply(__PACKAGE__->engine);
}

1;

