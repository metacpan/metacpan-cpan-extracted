use Mojo::Base -strict;
use lib 't/lib';

use Test::More tests => 3;

use Bot::Telegram;
use Bot::Telegram::Test;

my $bot;

subtest init_api => sub {
  plan tests => 3;

  $bot = Bot::Telegram -> new;

  subtest 'Refused to initialize WWW::Telegram::BotAPI without a token', sub {
    plan tests => 2;

    eval { $bot -> init_api };
    is ref($@), 'Bot::Telegram::X::InvalidArgumentsError', 'error type';
    is $@ -> message, 'No token provided', 'error message';
  };

  eval { $bot -> init_api(token => 'something') };
  is ref $bot -> api, 'WWW::Telegram::BotAPI', 'Sucessfully initialized WWW::Telegram::BotAPI using the provided token';

  is $bot -> api -> {async}, 1, 'API async defaults to true';
};

subtest api_request => sub {
  plan tests => 1;

  my $api = bot_api json_response({}), sub {
    my ($method, $postdata) = @_;

    is_deeply [$method, $postdata],
              [sendMessage => { text => 'Hello world', chat_id => 55 }],
              'arguments proxied correctly';
  };

  $bot -> api($api);
  $bot -> api_request(sendMessage => { text => 'Hello world', chat_id => 55 });
  $bot -> start_polling -> stop_polling;
};

subtest api_request_p => sub {
  plan tests => 4;

  # Simulate some API action
  # It doesn't matter what exactly we are "doing" - responses are pre-defined anyway
  my @args = (sendMessage => { text => 'Hello world', chat_id => 55 });

  # 1
  my $api = bot_api json_response({ ok => \1 }), sub {
    my ($method, $postdata) = @_;

    is_deeply [$method, $postdata], [@args],
              'arguments proxied correctly';
  };

  $bot -> api($api);
  $bot -> api_request_p(@args) -> wait;

  # 2, 3, 4
  my @responses = (json_response({ ok => \1, result => [] }),  # resolve
                   json_response({ ok => \0, result => [] }),  # reject
                   json_response({ ok => \0, result => [] })); # reject (this one contains a tx error)

  $responses[2] -> error('some irrelevant error message');

  $api = bot_api @responses;
  $bot -> api($api);

  $bot
    -> api_request_p(@args)
    -> then  (sub { pass 'resolve for "ok": true' })
    -> catch (sub { fail 'resolve for "ok": true' })
    -> wait;

  $bot
    -> api_request_p(@args)
    -> then  (sub { fail 'reject for "ok": false' })
    -> catch (sub { pass 'reject for "ok": false' })
    -> wait;

  $bot
    -> api_request_p(@args)
    -> then  (sub { fail 'reject for transaction errors' })
    -> catch (sub { pass 'reject for transaction errors' })
    -> wait;
};

done_testing;
