use Test::More tests => 4;
use strict; use warnings;
BEGIN{
  use_ok('Bot::Cobalt::IRC');
}

my $irc = new_ok('Bot::Cobalt::IRC');

can_ok($irc, qw/
  Cobalt_register
  Cobalt_unregister
/);

## Quickly test role consumption also:
can_ok($irc, qw/
  Bot_message
  Bot_notice
  Bot_action
  Bot_send_raw
  Bot_mode
  Bot_topic
  Bot_kick
  Bot_join
  Bot_part
  Bot_ircplug_connect
  Bot_ircplug_disconnect
  
  Bot_public_cmd_server
/ );
