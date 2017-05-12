package AuthTestApp;
use strict;
use warnings;
use base qw/Catalyst/;
use Catalyst qw/
    Authentication
/;

our %users;
__PACKAGE__->config(
    'Plugin::Authentication' => {
        default_realm => 'test',
        test => {
            credential => {
                class             => 'TypeKey',
                key_cache         => '/var/cache/webapp/auth_test_app',
                version           => '1',
                skip_expiry_check => '1',
                key_url           => 'http://www.typekey.com/extras/regkeys.txt',
            },
            store => {
                class => 'Minimal',
                users => \%users,
            },
        },
    },
);
%users = (
    foo => { password => 's3cr3t', },
);
__PACKAGE__->setup;

1;
