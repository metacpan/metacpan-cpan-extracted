use Test::More tests => 25;
use strict; use warnings;

BEGIN {
  use_ok( 'Bot::Cobalt::Timer' );
}

{
  package 
    MockCore;
  use strict; use warnings FATAL => 'all';
  use Test::More;
  sub new { bless {}, shift }
  sub send_event { pass('send_event called') }
}


my $timer = new_ok( 'Bot::Cobalt::Timer' => [
    core  => MockCore->new,
    delay => 60,
    id    => 'mytimer',
    event => 'test',
    alias => 'Pkg::Snackulate', 
  ],
);

is( $timer->delay, 60, 'delay()' );
is( $timer->event, 'test', 'event()' );
is( $timer->alias, 'Pkg::Snackulate', 'alias()' );
ok( $timer->has_id, 'has_id()' );
is( $timer->id, 'mytimer', 'id()' );
is( $timer->type, 'event', 'type()' );

ok( $timer->at, 'delay() -> at()' );
ok( $timer->at(1), 'reset at()' );
is( $timer->at, 1, 'at() is reset' );

ok( $timer->args(['arg1', 'arg2']), 'set args()' );
is_deeply( $timer->args, ['arg1', 'arg2'], 'get args()' );

ok( $timer->is_ready, 'timer would be ready' );
ok( $timer->execute_if_ready, 'execute_if_ready()' );

my $mtimer = new_ok( 'Bot::Cobalt::Timer' => [
    core    => MockCore->new,
    context => 'Test',
    target  => 'target',
    text    => 'testing things',
  ],
);

is( $mtimer->context, 'Test', 'context()' );
is( $mtimer->target, 'target', 'target()' );
is( $mtimer->text, 'testing things', 'text()' );
is( $mtimer->type, 'msg', 'assume msg type()' );
is( $mtimer->at, 0, 'no delay set' );

ok( $mtimer->delay(900), 'set delay()' );
ok( $mtimer->at, 'at() is set' );
ok( !$mtimer->execute_if_ready, 'no execute()' );
