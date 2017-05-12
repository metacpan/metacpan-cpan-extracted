use strict;
use Test::More tests => 23;
use Mojolicious::Lite;
use Test::Mojo;
use Test::Exception;

get '/' => sub { shift->render(text => 'ciao') };

my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200)->content_is('ciao');

my @records;
lives_ok {
   plugin 'Bot::ChatBots::Messenger',
     instances => [
      [
         WebHook => path => '/messenger',
         processor    => sub { push @records, shift },
         verify_token => 'galook',
      ],
     ];
} ## end lives_ok
'plugin definition lives';

my $cbc;
lives_ok { $cbc = app->chatbots->messenger; } 'call to helper works';
isa_ok $cbc, 'Bot::ChatBots::Messenger';

my @instances = @{$cbc->instances};
is scalar(@instances), 1, 'one instance present';
isa_ok $instances[0], 'Bot::ChatBots::Messenger::WebHook';

$t->get_ok('/messenger')->status_is(403);
$t->get_ok('/messenger?hub.verify_token=INVALID&hub.mode=subscribe'
     . '&hub.challenge=whatever')->status_is(403);
$t->get_ok('/messenger?hub.verify_token=galook&hub.mode=subscribe'
     . '&hub.challenge=whatever')->status_is(200);

my $message = message();
$t->post_ok('/messenger', json => $message)->status_is(204);

is scalar(@records), 2, '2 messages back';

is $records[0]{source}{technology}, 'messenger', 'technology';
is $records[0]{sender}{id},         'USER_ID',   'sender id';
is $records[0]{channel}{id},        'USER_ID',   'channel id';
is $records[0]{channel}{fqid},      'USER_ID',   'channel fqid';
is_deeply $records[0]{payload},
  $message->{entry}[0]{messaging}[0]{message}, 'payload';
is_deeply $records[0]{update}, $message->{entry}[0]{messaging}[0],
  'update';

done_testing();

sub message {
   return {
      "object" => "page",
      "entry"  => [
         {
            "id"        => "PAGE_ID",
            "time"      => "some time",
            "messaging" => [
               {
                  "sender" => {
                     "id" => "USER_ID"
                  },
                  "recipient" => {
                     "id" => "PAGE_ID"
                  },
                  "timestamp" => 1458692752478,
                  "message"   => {
                     "mid"  => "mid.1457764197618:41d102a3e1ae206a38",
                     "seq"  => 72,
                     "text" => "hello, world!",
                     "quick_reply" => {
                        "payload" => "DEVELOPER_DEFINED_PAYLOAD"
                     }
                  }
               },
               {
                  "sender" => {
                     "id" => "USER_ID"
                  },
                  "recipient" => {
                     "id" => "PAGE_ID"
                  },
                  "timestamp" => 1458692752478,
                  "message"   => {
                     "mid"  => "mid.1457764197618:41d102a3e1ae206a38",
                     "seq"  => 76,
                     "text" => "hello, world!",
                     "quick_reply" => {
                        "payload" => "DEVELOPER_DEFINED_PAYLOAD"
                     }
                  }
               }
            ]
         }
      ]
   };
} ## end sub message
