package TestApp;

use strict;

use Catalyst qw/
    Authentication
    Authentication::Store::Minimal
    Authentication::Credential::Password
/;

TestApp->config(
    name => 'TestApp',
    'Plugin::Authentication' => {
        users => {
            'admin' => { password => 'admin' }
        }
    }
);
TestApp->setup;

1;
