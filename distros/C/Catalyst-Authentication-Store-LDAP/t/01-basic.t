use strict;
use Test::More tests => 2;
use_ok('Catalyst');
use_ok('Catalyst::Authentication::Store::LDAP');

diag("Testing Catalyst::Authentication::Store::LDAP version " .
      $Catalyst::Authentication::Store::LDAP::VERSION);
diag("Testing Catalyst version " . $Catalyst::VERSION);

