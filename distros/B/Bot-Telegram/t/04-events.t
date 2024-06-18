use Mojo::Base -strict;
use lib 't/lib';

use Test::More tests => 4;

use Bot::Telegram;
use Bot::Telegram::Test;
use Bot::Telegram::Test::Updates;
use Mojo::IOLoop;

subtest 'default watchers', sub {
  plan tests => 2;

  subtest polling_error => sub {
    plan tests => 4;

    my $bot = Bot::Telegram -> new;
    my $log = $bot -> log;
    my $messages = $log -> capture('warn');

    my @res = (
      # valid
      json_response { ok => \1, result => [update message => 1] },
      # api
      json_response { ok => \0, description => 'catch me api', error_code => 500 },
      # agent
      json_response -> error({ message => 'catch me agent' }),
      # unknown
      json_response
    );

    $bot -> api(bot_api @res) -> start_polling;
    Mojo::IOLoop -> start;

    my ($api, $agent, $unknown) = @$messages;
    is scalar @$messages, 3, 'got 3 failures as expected';
    like $api,     qr/Polling failed \(error type: api\): catch me api/, 'api error looks similar';
    like $agent,   qr/Polling failed \(error type: agent\): catch me agent/, 'agent error looks similar';
    like $unknown, qr/Polling failed \(error type: unknown\): no details available/, 'unknown error looks similar';
  };

  subtest callback_error => sub {
    plan tests => 3;

    my $bot = Bot::Telegram -> new;
    my $log = $bot -> log;
    my $res = json_response {
      ok => \1,
      result => [ map { state $i = 0 ; update $_ => $i++ } qw/message edited_message callback_query/ ]
    };

    my $messages = $log -> capture('warn');
    my $upd_counter = 0;

    my $count_update = sub { ++ $upd_counter };

    $bot
      -> api(bot_api $res)
      -> set_callbacks(
        message => sub { die 'failed to process message' },
        edited_message => $count_update,
        callback_query => $count_update)
      -> start_polling;

    Mojo::IOLoop -> start;

    is scalar @$messages, 1, 'got 1 failure as expected';
    is $upd_counter, 2, 'processed 2 updates as expected';
    like $$messages[0], qr/Update processing failed: failed to process message/,
        'error message looks similar';
  };
};

subtest callback_error => sub {
  plan tests => 2;

  my $bot = Bot::Telegram -> new;
  my $res = json_response { ok => \1, result => [update message => 1] };

  $bot -> api(bot_api $res);
  $bot -> set_callbacks(message => sub { This shit will definitely die });

  my ($pass, @args) = 0;
  $bot -> unsubscribe('callback_error');
  $bot -> on(callback_error => sub { @args = @_ });

  $bot -> start_polling;
  Mojo::IOLoop -> one_tick;
  $bot -> stop_polling;

  subtest arguments => sub {
    plan tests => 2;
    my ($bot, $update, $eval_error) = @args;

    note explain \@args;

    ok ref $bot eq 'Bot::Telegram';
    ok ref $update eq 'HASH';
    $pass++ if !!$eval_error;
  };

  ok $pass, 'callback error caught';
};

subtest unknown_update => sub {
  plan tests => 2;

  my $bot = Bot::Telegram -> new;
  my $res = json_response {
    ok   => \1,  
    result => [
      (update message => 1),
      (update thing => 2),
    ],
  };

  $bot -> api(bot_api $res);
  # $bot -> unsubscribe('unknown_update'); # there's nothing by default
  $bot -> set_callbacks(message => sub { 0 }); # make 'message' a "known" update

  my ($pass, @args) = 0;
  $bot -> on(unknown_update => sub { @args = @_ });

  $bot -> start_polling;
  Mojo::IOLoop -> one_tick;
  $bot -> stop_polling;

  subtest arguments => sub {
    plan tests => 2;
    my ($bot, $update) = @args;
    my $exists = exists $$update{thing};

    note explain \@args;

    ok ref $bot  eq 'Bot::Telegram';
    ok ref $update eq 'HASH';
    $pass++ if $exists;
  };

  is $pass, 1, 'unknown update caught';
};

subtest polling_error => sub {
  plan tests => 3;

  my $bot = Bot::Telegram -> new;

  my @res = (
    # [unknown] something inconsistent
    (json_response undef),
    # [agent] agent failure ($res -> error, also available as $tx -> error)
    (json_response { ok => \1, result => 'actually, the response body is irrelevant in this case' }),
    # [api] error from the API (error_code exists inside the response)
    (json_response { ok => \0, description => 'something bad happened', error_code => 500 }));

  $res[1] -> error('error does exist; contents are irrelevant');

  my @handlers = (
    sub {
      my ($bot, $tx, $type) = @_;

      subtest 'polling error arguments (unknown)' => sub {
        plan tests => 3;

        is ref $bot, 'Bot::Telegram';
        is ref $tx,  'Mojo::Transaction::HTTP';
        is $type, 'unknown';
      };
    },

    sub {
      my ($bot, $tx, $type) = @_;

      subtest 'polling error arguments (agent)' => sub {
        plan tests => 3;

        is ref $bot, 'Bot::Telegram';
        is ref $tx,  'Mojo::Transaction::HTTP';
        is $type, 'agent';
      };
    },

    sub {
      my ($bot, $tx, $type) = @_;

      subtest 'polling error arguments (api)' => sub {
        plan tests => 3;

        is ref $bot, 'Bot::Telegram';
        is ref $tx,  'Mojo::Transaction::HTTP';
        is $type, 'api';
      };
    });

  $bot -> api(bot_api @res);

  for my $handler (@handlers) {
    $bot -> unsubscribe('polling_error');
    $bot -> on(polling_error => $handler);
    $bot -> start_polling;

    Mojo::IOLoop -> one_tick;
    $bot -> stop_polling;
  }
};

done_testing;