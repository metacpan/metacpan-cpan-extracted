use Test::More;

plan skip_all => "Optional modules (DBD::Cassandra) not installed"
  unless eval {
      require DBD::Cassandra;
  };

plan tests => 1;

use_ok('Apache::Session::Browseable::Cassandra');
