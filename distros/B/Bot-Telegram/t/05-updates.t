use Mojo::Base -strict;
use lib 't/lib';

use Test::More tests => 2;

use Bot::Telegram;
use Bot::Telegram::Test;
use Bot::Telegram::Test::Updates;
use Mojo::IOLoop;

subtest 'on/off' => sub {
  plan tests => 3;

  my $bot = Bot::Telegram -> new;
  my $api = bot_api;

  my $message = sub { 'this is a callback for message' };
  my $edited_message = sub { 'this is a callback for edited_message' };

  $bot -> set_callbacks(message => $message, edited_message => $edited_message);

  is_deeply [ sort keys %{$bot -> callbacks} ], [qw/edited_message message/],
            'set callbacks';

  subtest subs => sub {
    is $bot -> callbacks -> {message}, $message;
    is $bot -> callbacks -> {edited_message}, $edited_message;
  };

  $bot -> remove_callbacks(qw/message edited_message/);
  is_deeply [ keys %{$bot -> callbacks} ], [],
            'remove callbacks';
};

subtest 'update types recognition' => sub {
  my $upds = [];
  my @list = qw/message callback_query inline_query foobar/;
  my $update_id = 0;

  plan tests => 4;

  push @$upds, (update $_ => $update_id++) for @list;

  my $bot = Bot::Telegram -> new;
  my $api = bot_api
    json_response {
      ok     => \1,
      result => $upds,
    };

  $bot -> api($api);

  my $correctly_recognized = [];

  $bot -> set_callbacks($_ => updcheck $_) for @list;

  $bot -> start_polling;
  Mojo::IOLoop -> one_tick;
  $bot -> stop_polling;
};

done_testing;
