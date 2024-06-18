#!/usr/bin/env perl

use Mojolicious::Lite;
use Bot::Telegram;

my $token  = $ENV{TOKEN} or die 'No Bot API token provided';
my $host   = $ENV{HOST} or die 'No webhook base URL provided'; # actually proto + host + port, e.g. https://example.com:8443
my $secret = join '', map { int rand $_ } 1 .. 9; # generate a random secret

# Can be used for manual testing
# curl -k -X POST -H 'X-Telegram-Bot-Api-Secret-Token: $secret' -H 'Content-Type: application/json' -d $DATA $ENV{HOST}/hook
# See: https://core.telegram.org/bots/webhooks#testing-your-bot-with-updates
app -> log -> info("secret: $secret");

my $bot = Bot::Telegram
  -> new
  -> init_api(token => $token);

post '/hook', sub {
  (my $c = shift) -> render(text => 'Thanks!');
  app -> log -> info('incoming request from', $c -> tx -> remote_address);

  {
    no warnings 'uninitialized'; # a bit of common::sense - there might be no secret present at all

    return app -> log -> warn('invalid secret')
      unless $c -> req
                -> headers
                -> header('X-Telegram-Bot-Api-Secret-Token')
                eq $secret;
  }

  $bot -> process_update($c -> req -> json);
};

$bot -> set_callbacks(message => sub {
  my (undef, $update) = @_;
  my $chat_id = $$update{message}{from}{id};
  my $text    = $$update{message}{text};

  eval {
    $bot -> api -> sendMessage({
      chat_id => $chat_id,
      text => $text eq '/start' ? 'Hey there!' : "You said: $text",
    });
  };
  
  if ($@) {
    my $e = $bot -> api -> parse_error;
    app -> log -> error("sendMessage failed: $e->{msg}");
  }
});

eval {
  my $res = $bot -> api -> setWebhook({
    url => "$host/hook",
    secret_token => $secret,
  });
};

if ($@) {
  app -> log
      -> fatal("setWebhook failed:", $bot -> api -> parse_error -> {msg});
} else {
  app -> start;
}
