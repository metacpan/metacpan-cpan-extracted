use Test::More;

plan skip_all => "Optional modules (DBI) not installed"
  unless eval {
      require DBI;
  };

plan tests => 1;

use_ok('Apache::Session::Browseable::Store::DBI');
