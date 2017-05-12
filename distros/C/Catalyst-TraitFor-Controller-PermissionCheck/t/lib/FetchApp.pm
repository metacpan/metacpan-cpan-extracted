package FetchApp;

use strict;

use Catalyst qw/
    Authentication
    Authentication::Store::Minimal
    Authentication::Credential::Password
/;

FetchApp->config(
    name => 'FetchApp',
    'Plugin::Authentication' => {
        users => {
            'admin' => { password => 'admin' }
        }
    }
);
FetchApp->setup;

1;
