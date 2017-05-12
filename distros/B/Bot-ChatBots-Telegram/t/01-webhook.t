use strict;
use Test::More tests => 20;
use Mojolicious::Lite;
use Test::Mojo;
use Test::Exception;

get '/' => sub { shift->render(text => 'ciao') };

my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200)->content_is('ciao');

my @records;
lives_ok {
   plugin 'Bot::ChatBots::Telegram',
     instances => [
      [
         WebHook => path => '/telegram',
         processor => sub { push @records, shift },
      ],
     ];
} ## end lives_ok
'plugin definition lives';

my $cbc;
lives_ok { $cbc = app->chatbots->telegram; } 'call to helper works';
isa_ok $cbc, 'Bot::ChatBots::Telegram';

my @instances = @{$cbc->instances};
is scalar(@instances), 1, 'one instance present';
isa_ok $instances[0], 'Bot::ChatBots::Telegram::WebHook';

$t->post_ok('/telegram')->status_is(204);
is scalar(@records), 0, 'no message back';

my $message = message();
$t->post_ok('/telegram', json => $message)->status_is(204);

is scalar(@records), 1, '1 message back';
is $records[0]{source}{technology}, 'telegram', 'technology';
is $records[0]{sender}{id}, '1111111', 'sender id';
is $records[0]{channel}{id}, '1111111', 'channel id';
is $records[0]{channel}{fqid}, 'private/1111111', 'channel fqid';
is_deeply $records[0]{payload}, $message->{message}, 'payload';
is_deeply $records[0]{update}, $message, 'update';

done_testing();

sub message {
   return {
      "update_id" => 10000,
      "message"   => {
         "date" => 1441645532,
         "chat" => {
            "last_name"  => "Test Lastname",
            "id"         => 1111111,
            "type"       => "private",
            "first_name" => "Test Firstname",
            "username"   => "Testusername"
         },
         "message_id" => 1365,
         "from"       => {
            "last_name"  => "Test Lastname",
            "id"         => 1111111,
            "first_name" => "Test Firstname",
            "username"   => "Testusername"
         },
         "text" => "/start"
      }
   };
} ## end sub message
