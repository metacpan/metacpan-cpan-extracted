use Test::More tests => 15;
use strict; use warnings;

BEGIN{
  use_ok('Bot::Cobalt::Core::ContextMeta::Auth');
}

my $cmeta = new_ok('Bot::Cobalt::Core::ContextMeta::Auth');
isa_ok($cmeta, 'Bot::Cobalt::Core::ContextMeta');

my $mask;
ok( $cmeta->add(
    Context  => 'Context',
    Username => 'someuser',
    Nickname => 'somebody',
    Host     => 'somebody!user@example.org',
    Flags    => { SUPERUSER => 1 },
    Level    => 3,
    Alias    => 'TestPkg',
  ),
  'Auth->add'
);

ok( $cmeta->level('Context', 'somebody') == 3, 'level()' );

ok( $cmeta->username('Context', 'somebody') eq 'someuser', 'username()' );
ok( $cmeta->user('Context', 'somebody') eq 'someuser', 
  'user() same as username()' 
);

ok( $cmeta->host('Context', 'somebody') eq 'somebody!user@example.org', 
  'host()' 
);

ok( $cmeta->alias('Context', 'somebody') eq 'TestPkg', 'alias()' );

ok( $cmeta->move('Context', 'somebody', 'nobody'), 'move()' );
ok( $cmeta->has_flag('Context', 'nobody', 'SUPERUSER'), 'has_flag()' );

ok( $cmeta->drop_flag('Context', 'nobody', 'SUPERUSER'), 'drop_flag()' );

ok( !$cmeta->has_flag('Context', 'nobody', 'SUPERUSER'), '! has_flag()' );

ok( $cmeta->set_flag('Context', 'nobody', 'FLAG'), 'set_flag()' );

ok( $cmeta->has_flag('Context', 'nobody', 'FLAG'), 'has_flag after set_flag' );
