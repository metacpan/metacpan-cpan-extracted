use Mojo::Base -strict;
use lib 't/lib';

use Test::More tests => 5;

use Bot::Telegram;
use Bot::Telegram::Test;
use Bot::Telegram::Test::Updates;

my $update_id = 0;

subtest is_async => sub {
  plan tests => 3;

  my $bot = Bot::Telegram -> new;

  subtest 'API instance missing' => sub {
    plan tests => 2;

    eval { $bot -> is_async };
    is ref($@), 'Bot::Telegram::X::InvalidStateError', 'error type';

    if (ref $@ eq 'Bot::Telegram::X::InvalidStateError') {
      is $@ -> message, 'API is not initialized', 'error message';
    } else {
      diag $@;
      fail 'error message';
    }
  };

  $bot -> api(bot_api);

  is $bot -> is_async, 1, 'enabled';
  $bot -> api -> {async} = 0;
  is $bot -> is_async, 0, 'disabled';
};

subtest 'Looping in synchronous mode' => sub {
  plan tests => 2;

  my @UPDATES = qw/message edited_message callback_query/;
  my $req_counter = 0;

  my $bot = Bot::Telegram -> new;
  my $api = bot_api json_response({
    ok => \1,
    result => [map {update $_ => $update_id++} @UPDATES]
  }), json_response({
    ok => \1,
    result => [update something => 0]
  }), sub { ++ $req_counter };

  $bot -> api($api) -> api -> {async} = 0;

  my @processed;

  # let's make ourselves a callbacks generator to simplify things a little bit
  my $push = sub {
    my $name = shift;

    sub {
      shift; # discard $bot reference
      note "(callback) $name";
      push @processed, $name if ref shift -> {$name} eq 'HASH'
    }
  };

  $bot -> set_callbacks(
    (map { $_ => $_ -> $push } qw/message callback_query something/),
    edited_message => sub {
      ('edited_message' -> $push) -> (@_);

      # This will disable the polling loop once the second update is processed.
      # 'callback_query' will still get processed since it's already retrieved,
      #  but 'something' should never be reached.
      $bot -> stop_polling;
    }
  );

  $bot -> start_polling(interval => 3);

  is $req_counter, 1, 'made 1 request';
  is_deeply \@processed, \@UPDATES, 'processed all updates received during the first iteration';
};

subtest 'Events', sub {
  my $bot = Bot::Telegram -> new;
  $bot -> api(bot_api json_response { ok => \1, result => [update message => 1] });
  $bot -> set_callbacks(message => sub { die 'catch me if you can' });

  $bot -> api -> {async} = 0;

  my $passed;
  $bot -> unsubscribe('callback_error');
  $bot -> on(callback_error => sub {
    note 'inside the callback';
    $bot -> stop_polling;
    $passed = 1;
  });

  $bot -> start_polling;
  Mojo::IOLoop -> start;
  ok $passed, 'events do work in synchronous mode';
};

# see 01-polling.t for the original test
# this one does the same thing but in synchronous mode
subtest 'Can sustain errors', sub {
  plan tests => 3;

  my $tx_error_response = json_response {};
  $tx_error_response -> error('irrelevant error contents');

  my ($req_counter, $err_counter, $upd_counter) = qw/0 0 0/;

  my $bot = Bot::Telegram -> new;
  my $api = bot_api
    random_valid_polling_response, # valid
    json_response({}),             # invalid
    $tx_error_response,            # invalid
    random_valid_polling_response, # valid
    sub {
      note "polling (\$req_counter: $req_counter)";
      $bot -> stop_polling if ++$req_counter >= 4;
    };

  $api -> {async} = 0;

  $bot -> api($api);
  $bot -> unsubscribe('polling_error');
  $bot -> unsubscribe('callback_error');

  $bot -> on(polling_error => sub {
    note "caught an error (\$err_counter: $err_counter)";
    $err_counter++
  });

  $bot -> on(unknown_update => sub {
    note "got an update (\$upd_counter: $upd_counter)";
    $upd_counter++
  });

  $bot -> start_polling(interval => 0.2); # don't waste too much time sleeping
  Mojo::IOLoop -> start;

  is $req_counter, 4, 'kept polling';
  is $err_counter, 2, 'all errors caught';
  is $upd_counter, 6, 'all valid responses correctly processed';
};

subtest 'simulated Mojo::Transaction for polling_error', sub {
  plan tests => 4;

  my $err_agent = json_response {};
    my $err_api = json_response {
      ok => \0,
      description => 'some api failure',

      # WWW::Telegram::BotAPI::parse_error relies on this field to distinguish between api and agent error types
      # https://metacpan.org/dist/WWW-Telegram-BotAPI/source/lib/WWW/Telegram/BotAPI.pm#L243
      # https://core.telegram.org/bots/api#making-requests
      error_code => 500,
    };

    $err_agent -> error({ message => 'some agent failure' });

    # For consistency's sake. Doesn't really affect results (for now)
    $err_api -> code(500);

    my ($req_counter, $err_counter) = qw/0 0/;
    my $api = bot_api $err_agent, $err_api, sub { ++ $req_counter };

    $api -> {async} = 0;

    my $bot = Bot::Telegram -> new -> api($api);
    $bot -> unsubscribe('polling_error');
    $bot -> unsubscribe('callback_error');

    my $transactions = {};
    $bot -> on(polling_error => sub {
      my (undef, $tx, $reason) = @_;
      note "(polling_error) $reason";
      $$transactions{$reason} = $tx;
      ++ $err_counter;
      $bot -> stop_polling if $req_counter >= 2;
    });

    $bot -> start_polling;

    is $req_counter, 2, 'performed 2 requests as expected';
    is $err_counter, 2, 'got 2 errors as expected';

    is_deeply $$transactions{api}, {
      error => {
        code => '500',
        type => 'api',
        msg  => 'some api failure'
      }
    }, 'contents: api';

    is_deeply $$transactions{agent}, {
      error => {
        type => 'agent',
        msg  => 'some agent failure'
      }
    }, 'contents: agent';
};

done_testing;
