use strict;
use Test::More tests => 13;
use Test::Exception;

BEGIN {
   (my $subdir = __FILE__) =~ s{t$}{d}mxs;
   unshift @INC, $subdir;
}

use Bot::ChatBots::Whatever::Sender;

my $sender;
lives_ok { $sender = Bot::ChatBots::Whatever::Sender->new }
'default constructor lives';

isa_ok $sender, 'Bot::ChatBots::Whatever::Sender';
ok !$sender->has_recipient, 'no recipient by default';

my $tube;
lives_ok { $tube = $sender->processor } 'call to processor method lives';
isa_ok $tube, 'CODE';

my $outcome;
lives_ok { $outcome = $tube->({some => 'thing'}) }
'call to processor sub lives';
is_deeply $outcome, {some => 'thing'}, 'processor passes stuff through';

is scalar($sender->sent), 0, 'no message was "sent"';

$sender->reset;
my $msg = {send_message => {what => 'ever'}};
lives_ok { $outcome = $tube->($msg) } 'processor sub lives (again)';
is_deeply $outcome, $msg, 'again stuff passes through';
is_deeply $outcome, {
   send_message => {what => 'ever'},
   sent_message => {what => 'ever'},
}, 'final byproduct';

is scalar($sender->sent), 1, 'one message was "sent"';
my ($sent) = $sender->sent;
is_deeply $sent, $msg->{send_message}, 'what was "sent"';

done_testing();
