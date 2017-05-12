use Test::More tests => 32;
use strict; use warnings;

## FIXME colorize string then check stripped() ?

BEGIN {
  use_ok('Bot::Cobalt::IRC::Message');
  use_ok('Bot::Cobalt::IRC::Message::Public');
}

my $msg = new_ok( 'Bot::Cobalt::IRC::Message' => [
   src     => 'somebody!somewhere@example.org',
   context => 'Context',
   message => 'Some IRC message',
   targets => [ 'JoeUser' ],
 ]
);
isa_ok( $msg, 'Bot::Cobalt::IRC::Event' );

ok( $msg->src_nick eq 'somebody', 'src_nick()' );
ok( $msg->src_user eq 'somewhere', 'src_user()' );
ok( $msg->src_host eq 'example.org', 'src_host()' );

ok( $msg->context eq 'Context', 'context()' );
ok( $msg->message eq 'Some IRC message', 'message()' );
ok( $msg->target eq 'JoeUser', 'target()');
ok( $msg->stripped eq 'Some IRC message', 'stripped()' );

ok( $msg->targets([ 'Bob', 'Sam' ]), 'Reset targets()' );
ok( $msg->target eq 'Bob', 'target() after reset' );


is_deeply( $msg->message_array,
  [ 'Some', 'IRC', 'message' ],
);

is_deeply( $msg->message_array_sp,
  [ 'Some', 'IRC', 'message' ],
);

ok( $msg->message( 'Changed message' ), 'Reset message()' );

is_deeply( $msg->message_array,
  [ 'Changed', 'message' ],
);

is_deeply( $msg->message_array_sp,
  [ 'Changed', 'message' ],
);

ok( $msg->message( '  Leading spaces'), 'Reset message() again' );

is_deeply( $msg->message_array,
  [ 'Leading', 'spaces' ],
);

is_deeply( $msg->message_array_sp,
  [ '', '', 'Leading', 'spaces' ],
);

undef $msg;

my $pub = new_ok( 'Bot::Cobalt::IRC::Message::Public' => [
    src     => 'somebody!somewhere@example.org',
    context => 'Main',
    message => 'Public IRC message',
    targets => [ '#chan1', '#another' ],
  ]
);

isa_ok( $pub, 'Bot::Cobalt::IRC::Message' );

ok( $pub->channel eq '#chan1', 'channel()' );

my $cmd = new_ok( 'Bot::Cobalt::IRC::Message::Public' => [
    src     => 'somebody!somewhere@example.org',
    context => 'Main',
    message => '!public cmd message',
    targets => [ '#chan1', '#another' ],
  ]
);

ok( $cmd->cmd eq 'public', 'cmd()' );

ok( $cmd->message( 'Not a command'), 'Change message()' );

ok( !$cmd->cmd(), 'cmd() dropped' );

ok( !$cmd->highlight(), 'No highlight()' );

ok( $cmd->myself('Botty'), 'Set myself()' );

ok( $cmd->message( 'Botty: snacks are tasty' ), 
  'Set highlight message()'
);

ok( $cmd->highlight, 'highlight()' );
