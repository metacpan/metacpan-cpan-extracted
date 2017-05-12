package OpenApp;

use strict;

use Catalyst qw/
    Authentication
    Authentication::Store::Minimal
    Authentication::Credential::Password
/;

OpenApp->config(
    name => 'OpenApp',
    'Plugin::Authentication' => {
        users => {
            'admin' => { password => 'admin' }
        }
    }
);
OpenApp->setup;

1;
