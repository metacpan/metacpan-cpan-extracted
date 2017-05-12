use Test::More tests => 5;

BEGIN {
  use_ok( 'Bot::Cobalt::Plugin::RSS' );
  use_ok( 'Bot::Cobalt::Plugin::RSS::Conf' );
}

new_ok( 'Bot::Cobalt::Plugin::RSS' );
can_ok( 'Bot::Cobalt::Plugin::RSS', 'Cobalt_register', 'Cobalt_unregister' );

ok( Bot::Cobalt::Plugin::RSS::Conf->conf(), 'conf()' );
