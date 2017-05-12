use strict;
use Test::More tests => 18;
use Mock::Quick;
use Test::Exception;
use Bot::ChatBots::Messenger::Sender;
use Mojolicious;

my $sender;

throws_ok { $sender = Bot::ChatBots::Messenger::Sender->new() }
qr{token}mxs, 'complains about token';

lives_ok {
   $sender = Bot::ChatBots::Messenger::Sender->new(token => 'whatever');
}
'constructor lives';

like $sender->url, qr{https://graph\.facebook\.com/}mxs, 'url';
ok !$sender->has_callback,  'no callback set';
ok !$sender->has_recipient, 'no recipient set';

lives_ok {
   $sender = Bot::ChatBots::Messenger::Sender->new(
      token => 'whatever',
      url   => 'http://www.example.com/the/api'
   );
} ## end lives_ok
'constructor lives (setting url)';

my @fuas;
my $fake_ua = qobj(post => qmeth { shift; push @fuas, [@_] });

lives_ok { $sender->ua($fake_ua) } 'can set ua';

throws_ok { $sender->send_message('NO RECIPIENT!') } qr{no\ recipient}mxs,
  'complains about recipient';

@fuas = ();
lives_ok {
   $sender->send_message(
      {
         message   => {text => 'whatever'},
         recipient => {id   => 'me'},
      }
   );
} ## end lives_ok
'send complete, regular message lives';
is scalar(@fuas), 1, '1 post sent';

my @ua_args = @{$fuas[0]};
is_deeply $fuas[0],
  [
   'http://www.example.com/the/api?access_token=whatever',
   {Accept => 'application/json'},
   json => {
      message   => {text => 'whatever'},
      recipient => {id   => 'me'},
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
   'http://www.example.com/the/api?access_token=whatever',
   {Accept => 'application/json'},
   json => {
      message   => {text => 'hey'},
      recipient => {id   => 'you'},
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
   'http://www.example.com/the/api?access_token=whatever',
   {Accept => 'application/json'},
   json => {
      message   => {text => 'hey no explicit recipient'},
      recipient => {id   => 'they'},
   }
  ],
  'what was sent in post';

done_testing();
