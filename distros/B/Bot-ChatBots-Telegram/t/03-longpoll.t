use strict;
use Test::More tests => 20;
use Test::Exception;
use Mock::Quick;
use Bot::ChatBots::Telegram::Sender;
use Bot::ChatBots::Telegram::LongPoll;

my (@fuas, %settings);
my $telegram = qobj(
   api_request => qmeth { shift; push @fuas, [@_] },
   agent => qobj(
      connect_timeout => qmeth {
         my $self = shift;
         $settings{connect_timeout} = shift;
         return $self;
      },
      inactivity_timeout => qmeth {
         my $self = shift;
         $settings{inactivity_timeout} = shift;
         return $self;
      },
      max_redirects => qmeth {
         my $self = shift;
         $settings{max_redirects} = shift;
         return $self;
      },
   ),
);
my $sender;
lives_ok {
   $sender = Bot::ChatBots::Telegram::Sender->new(
      token    => 'whatever',
      telegram => $telegram,
   );
} ## end lives_ok
'constructor for ::Sender lives with custom `telegram` object';

my ($lp, @records);
lives_ok {
   $lp = Bot::ChatBots::Telegram::LongPoll->new(
      sender => $sender,
      start  => 0,                # do not start loop
      token  => $sender->token,
      processor => sub { push @records, shift; return $records[-1] },
   );
} ## end lives_ok
'constructor for ::LongPoll lives';
isa_ok $lp, 'Bot::ChatBots::Telegram::LongPoll';

my $poller;
lives_ok { $poller = $lp->poller } 'poller retrieval lives';

is_deeply \%settings,
  {
   connect_timeout    => 20,
   inactivity_timeout => 305,
   max_redirects      => 5,
  },
  'settings for telegram ua';

@fuas = ();
lives_ok { $poller->() } 'call to the poller lives';

use Data::Dumper; $Data::Dumper::Indent = 1;

is scalar(@fuas), 1, 'one call to the sender done';
my ($call) = @fuas;
is scalar(@$call), 3, 'call to sender had three parameters';

my ($method, $query, $callback) = @$call;
is $method, 'getUpdates', 'call was to getUpdates';
is_deeply $query, {offset => 0, timeout => 300}, 'query parameters';
is ref($callback), 'CODE', 'callback was set';

my $message = message();
my $tx = qobj(
   res => qobj(
      json => {
         ok => 1, # some true value is fine
         result => [ $message ],
      },
   ),
);

@records = ();
lives_ok { $callback->({}, $tx) } 'callback lives';

is scalar(@records), 1, 'one element processed by callback';
is $records[0]{source}{technology}, 'telegram', 'technology';
is $records[0]{source}{query}{offset}, 10001, 'offset was increased';
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
