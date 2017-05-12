use Test::More;

plan skip_all => "Optional modules (Net::LDAP) not installed"
  unless eval {
      require Net::LDAP;
  };

plan tests => 1;

$package = 'Apache::Session::Browseable::Store::LDAP';

use_ok($package);

