use Mojo::Base -strict;
use lib 't/lib';

use Test::More tests => 4;

use Bot::Telegram;
use Bot::Telegram::Test;

use Mojo::Promise;

my $bot = Bot::Telegram -> new -> api(bot_api map { json_response {} } 1 .. 5);

$bot -> on(polling_error => sub {
  for (my $reason = pop) {
    BAIL_OUT '"agent" type error should not occur here, fix your tests'
      unless /api/;
  }
});

$bot -> start_polling;

my $set_f;

subtest 'cannot set while polling loop is active', sub {
  plan tests => 2;

  eval { $bot -> set_webhook({ url => 'http://localhost/' }) };
  is ref($@), 'Bot::Telegram::X::InvalidStateError', 'error type';
  is $@ -> message, 'Disable long polling first', 'error message';
};

$bot -> stop_polling;

subtest 'cannot set without config', sub {
  plan tests => 2;

  eval { $bot -> set_webhook };
  is ref($@), 'Bot::Telegram::X::InvalidArgumentsError', 'error type';
  is $@ -> message, 'No config provided', 'error message';
};

eval { $bot -> set_webhook({ url => 'http://localhost/' }) };
ok !$@, 'set w/o callback';

$bot -> set_webhook(sub { $set_f = 1 });
timer { ok $set_f, 'set w/callback' } 0.25;

Mojo::IOLoop -> start;
done_testing;
