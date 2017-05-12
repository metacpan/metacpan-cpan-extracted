use Test::More;

plan skip_all => "Optional modules (Redis) not installed"
  unless eval {
      require Redis;
  };

plan tests => 1;

$package = 'Apache::Session::Browseable::Redis';

use_ok($package);

