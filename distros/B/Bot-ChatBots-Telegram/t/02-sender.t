use strict;
use Test::More tests => 18;
use Mock::Quick;
use Test::Exception;
use Bot::ChatBots::Telegram::Sender;
use Mojolicious;

my $sender;

throws_ok { $sender = Bot::ChatBots::Telegram::Sender->new() }
qr{token}mxs, 'complains about token';

lives_ok {
   $sender = Bot::ChatBots::Telegram::Sender->new(token => 'whatever');
}
'constructor lives';
ok !$sender->has_recipient, 'no recipient set';

my @fuas;
my $telegram = qobj(api_request => qmeth { shift; push @fuas, [@_] });
lives_ok { $sender->telegram($telegram) } 'can set telegram object';

# string comparison is OK here
is $sender->telegram, $telegram, 'telegram object actually set';

lives_ok {
   $sender = Bot::ChatBots::Telegram::Sender->new(
      token    => 'whatever',
      telegram => $telegram,
   );
} ## end lives_ok
'constructor lives (setting telegram object)';
is $sender->telegram, $telegram, 'telegram object actually set';

throws_ok { $sender->send_message('NO RECIPIENT!') }
qr{no\ chat\ identifier}mxs,
  'complains about recipient';

@fuas = ();
lives_ok {
   $sender->send_message(
      {
         text => 'whatever',
         chat_id   => 'me',
      }
   );
} ## end lives_ok
'send complete, regular message lives';
is scalar(@fuas), 1, '1 post sent';
is_deeply $fuas[0],
  [
     'sendMessage',
     {
       'chat_id' => 'me',
       'text' => 'whatever'
     }
  ],
  'what was sent in post';

@fuas = ();
lives_ok {
   $sender->send_message('hey', record => {channel => {id => 'you'}});
}
'send message with update for sender lives';
is scalar(@fuas), 1, '1 post sent';
is_deeply $fuas[0],
  [
     'sendMessage',
     {
       'text' => 'hey',
       'chat_id' => 'you',
     }
  ],
  'what was sent in post';

lives_ok { $sender->recipient('they') } 'set default recipient';

@fuas = ();
lives_ok {
   $sender->send_message('hey no explicit recipient');
}
'send message with default recipient';
is scalar(@fuas), 1, '1 post sent';
is_deeply $fuas[0],
  [
     'sendMessage',
     {
       'text' => 'hey no explicit recipient',
       'chat_id' => 'they',
     }
  ],
  'what was sent in post';

done_testing();
