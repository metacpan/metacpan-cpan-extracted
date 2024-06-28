use Mojo::Base -strict;
use lib 't/lib';

use Test::More tests => 12;

use Bot::Telegram;
use Bot::Telegram::Test;

use Mojo::Util qw/steady_time/;

my $bot = Bot::Telegram -> new -> api(bot_api);

$bot -> start_polling;
ok $bot -> is_polling, 'start';

subtest 'cannot start twice', sub {
  plan tests => 2;

  eval { $bot -> start_polling };
  is ref($@), 'Bot::Telegram::X::InvalidStateError', 'error type';
  is $@ -> message, 'Already running', 'error message';
};

subtest 'restart => 1: hot state', sub {
  eval { $bot -> start_polling(restart => 1) };
  ok !$@, 'no errors';
  diag explain $@ if $@;
  ok $bot -> is_polling, 'is polling';
};

$bot -> stop_polling;
ok !$bot -> is_polling, 'stop';

subtest 'restart => 1: cold state', sub {
  eval { $bot -> start_polling(restart => 1) };
  ok !$@, 'no errors';
  diag explain $@ if $@;
  ok $bot -> is_polling, 'is polling';
};


# Arguments

# 1
$bot -> stop_polling;

$bot -> api(bot_api json_response({}), sub {
  return unless shift eq 'getUpdates';
  is_deeply shift, { timeout => 20, offset => 0 }, 'config: defaults used';
});

$bot -> start_polling;

# 2
$bot -> stop_polling;

$bot -> api(bot_api json_response({}), sub {
  return unless shift eq 'getUpdates';
  is_deeply shift, { timeout => 22, offset => 0 }, 'config: override defaults';
});

$bot -> start_polling({ timeout => 22, offset => 0 }, restart => 1);

# 3
subtest 'config: custom with options' => sub {
  plan tests => 2;

  $bot -> api(bot_api json_response({}), sub {
    return unless shift eq 'getUpdates';
    is_deeply shift,
      { timeout => 30, allowed_updates => ['message'], offset => 0 },
      'custom config';
  });

  # NOTE: the polling loop is currently active
  eval { $bot -> start_polling({ timeout => 30, allowed_updates => ['message'] }, restart => 1) };
  ok !$@, 'named options';
};


# Multiple iterations (make sure the next _poll actually gets scheduled)

my $counter = 0;

$bot -> stop_polling;
$bot -> api(bot_api
  +(map {random_valid_polling_response} 1 .. 3), # this API "responds" 3 times
  sub { $counter++ }                             # count requests
);

# 1 / 0.2 = 5 update sets per second under ideal circumstances, given that no actual network activity is happening and "updates" are returned instantly
# We only have to process three update sets. One second is more than enough for the test to succeed.
$bot -> start_polling(interval => 0.2);

loop_for_a_second;
is $counter, 3, 'looping';


# Keep polling despite errors unless told otherwise

subtest 'can sustain errors', sub {
  plan tests => 3;

  my $tx_error_response = json_response {};
  $tx_error_response -> error('irrelevant error contents');

  my ($req_counter, $err_counter, $upd_counter) = qw/0 0 0/;

  my $api = bot_api
    random_valid_polling_response, # valid
    json_response({}),             # invalid
    $tx_error_response,            # invalid
    random_valid_polling_response, # valid
    sub {
      # poll four times (we don't have responses for more anyway)
      note "polling (\$req_counter: $req_counter)";
      $bot -> stop_polling if ++$req_counter >= 4;
    };

  $bot = Bot::Telegram -> new -> api($api);

  # Remove default subscribers so nothing gets in the way
  $bot -> unsubscribe('polling_error');
  $bot -> unsubscribe('callback_error');

  # $err_counter should be 2
  $bot -> on(polling_error => sub {
    note "caught an error (\$err_counter: $err_counter)";
    ++$err_counter
  });

  # $upd_counter should be 6, provided that a random_valid_polling_response set contains 3 updates by default
  # $api has two sets overall, meaning 3 * 2 = 6 updates to process
  $bot -> on(unknown_update => sub {
    note "got an update (\$upd_counter: $upd_counter)";
    ++$upd_counter
  });

  # $bot -> on(polling_error  => sub { $err_counter++ });
  # $bot -> on(unknown_update => sub { $upd_counter++ });

  $bot -> start_polling(interval => 0.1);
  Mojo::IOLoop -> start; # will turn off automatically once all connections are finished

  is $req_counter, 4, 'kept polling';
  is $err_counter, 2, 'all errors caught';
  is $upd_counter, 6, 'all valid responses correctly processed';
};

subtest 'rate limit awareness', sub {
  my $api = bot_api
    json_response { ok => \1, result => [update message => 1] },
    json_response {
      ok => \0,
      description => 'rate limit test',
      error_code => 429,
      parameters => { retry_after => 1 }
    },
    json_response { ok => \1, result => [update message => 2] };

  $bot = $bot = Bot::Telegram -> new -> api($api);
  my $messages = $bot -> log -> capture('info');
  my $polling_interval_after_rate_limit;

  my $stop = sub {
    $bot -> stop_polling;
    Mojo::IOLoop -> stop;
  };

  my $t = Mojo::IOLoop -> timer(3, $stop);

  $bot -> set_callbacks(message => sub {
    return unless pop -> {update_id} == 2;

    $polling_interval_after_rate_limit = $bot -> _polling_interval;

    $stop -> ();
    Mojo::IOLoop -> remove($t);
  });

  my $time_before = steady_time;

  $bot -> start_polling(interval => 0.1);
  Mojo::IOLoop -> start;

  my $time_after = steady_time;

  note explain \@$messages;
  my ($message) = grep { /Rate limit exceeded/ } @$messages;
  like $message, qr/Rate limit exceeded, waiting 1s before polling again/, 'rate limit log message exists';

  is $polling_interval_after_rate_limit, 0.1, 'polling interval was not affected by the rate limit timer';

  note "time_before: $time_before, time_after: $time_after";
  ok $time_after - $time_before >= 1, 'was on standby for (roughly) one second';
};

# config persistence
$bot = Bot::Telegram -> new -> api(bot_api random_valid_polling_response);

$bot -> start_polling;
my $config = $bot -> polling_config;
$bot -> stop_polling;
$bot -> start_polling;
$bot -> stop_polling;
Mojo::IOLoop -> start;

is $bot -> polling_config, $config, 'config is persistent between restarts';

done_testing;
