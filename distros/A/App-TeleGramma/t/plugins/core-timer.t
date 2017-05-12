use Test::More;

use strict;
use warnings;

use Telegram::Bot::Message;
use App::TeleGramma;
use App::TeleGramma::Constants qw/:const/;

use_ok('App::TeleGramma::Plugin::Core::Timer');

my ($expected_chat_id, $expected_text);
my $count = 0;

{
  no warnings 'once';
  *App::TeleGramma::send_message_to_chat_id = \&mock_send_message_to_chat_id;
}

my $app = App::TeleGramma->new;
my $t = App::TeleGramma::Plugin::Core::Timer->new;
ok($t, 'created');
$t->app($app);

my ($a_l, $h_l) = $t->register;
my $msg = Telegram::Bot::Message->new;
my $user = Telegram::Bot::Object::User->new(id => 123, username => 'fred');
$msg->chat($user);
$msg->from($user);

# help
$expected_text = "examples: /timer remind me to weed and feed in 3 hours";
$expected_chat_id = 123;
$msg->text("/timer");
is ($h_l->process_message($msg), PLUGIN_RESPONDED_LAST);
is ($count, 1);

# non matching help
$msg->text("/blah blah");
is($h_l->process_message($msg), PLUGIN_DECLINED);

# non matching timer set
$msg->text("/blah blah");
is($a_l->process_message($msg), PLUGIN_DECLINED);

# bad entry
$expected_text = "Sorry, I can't work out when you mean from '/timer remind me to impeach Trump tomorrow'";
$expected_chat_id = 123;
$msg->text("/timer remind me to impeach Trump tomorrow");
is($a_l->process_message($msg), PLUGIN_RESPONDED_LAST);
is ($count, 2);

# set a timer
$expected_text = "Will remind you 'weed and feed' in 1 second";
$expected_chat_id = 123;
$msg->text("/timer remind me to weed and feed in 1 second");
$a_l->process_message($msg);
is ($count, 3);

# sleep and see that we get the timer message
#sleep 1;
$expected_text = "Hey \@fred, this is your reminder to weed and feed";
$expected_chat_id = 123;
Mojo::IOLoop->one_tick;
is ($count, 4, 'now received 4 replies');

# bad timer
$expected_text = "Sorry, I can't work out when you mean from '1 hogshead'";
$expected_chat_id = 123;
$msg->text("/timer remind me to weed and feed in 1 hogshead");
$a_l->process_message($msg);
is ($count, 5);

# test the timer actually works
my $time = time();
$expected_text = "Will remind you 'weed and feed' in 5 seconds";
$expected_chat_id = 123;
$msg->text("/timer remind me to weed and feed in 5 seconds");
$a_l->process_message($msg);
is ($count, 6);

$expected_text = "Hey \@fred, this is your reminder to weed and feed";
$expected_chat_id = 123;
Mojo::IOLoop->one_tick;
is ($count, 7);
my $diff = time() - $time;
ok ($diff > 4 && $diff < 7, 'correct time has passed');

done_testing();

sub mock_send_message_to_chat_id {
  my $app     = shift;
  my $chat_id = shift;
  my $text    = shift;

  is ($text, $expected_text);
  is ($chat_id, $expected_chat_id);

  undef $expected_text;
  undef $expected_chat_id;
  $count++;
}
