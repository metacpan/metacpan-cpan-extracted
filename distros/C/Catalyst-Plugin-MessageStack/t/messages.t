#!perl

use strict;

use FindBin qw($Bin);
use lib "$Bin/lib";

use Test::More tests => 26;
use Catalyst::Test 'TestApp';
use Message::Stack;
use Message::Stack::Message;

my $c = TestApp->new;

is($c->reset_messages, 0, 'Clear the (non-existent) stack');
is($c->has_messages, 0, 'No messages in the stack');

is_deeply($c->message({
    scope => 'some_scope',
    message => 'this is a message',
    type => 'info',
    subject => 'verb',
    params => ['string_param', 10]
}), bless({
    messages => [
      bless({
        level   => "info",
        msgid   => "this is a message",
        scope   => "some_scope",
        subject => "verb",
        params  => ["string_param", 10],
      }, "Message::Stack::Message"),
   ],
}, "Message::Stack"), 'One message in the stash');


is_deeply($c->message({
    scope => 'some_scope',
    message => 'this is the second message',
    type => 'error',
    subject => 'ruler'
}), bless({
    messages => [
      bless({
        level   => "info",
        msgid   => "this is a message",
        scope   => "some_scope",
        subject => "verb",
        params  => ["string_param", 10],
      }, "Message::Stack::Message"),
      bless({
        level   => "error",
        msgid   => "this is the second message",
        scope   => "some_scope",
        subject => "ruler",
      }, "Message::Stack::Message"),
   ],
}, "Message::Stack"), 'Two messages in the stash');

my $msg = Message::Stack::Message->new({
    scope => 'some_other_scope',
    id => 'this is a third message',
    level => 'info',
    subject => 'ruler'
});
is_deeply($c->message($msg), bless({
    messages => [
      bless({
        level   => "info",
        msgid   => "this is a message",
        scope   => "some_scope",
        subject => "verb",
        params  => ["string_param", 10],
      }, "Message::Stack::Message"),
      bless({
        level   => "error",
        msgid   => "this is the second message",
        scope   => "some_scope",
        subject => "ruler",
      }, "Message::Stack::Message"),
      bless({
        level   => "info",
        msgid   => "this is a third message",
        scope   => "some_other_scope",
        subject => "ruler",
      }, "Message::Stack::Message"),
   ],
}, "Message::Stack"), 'Three messages in the stash');

my $msg2 = Message::Stack::Message->new({
    scope => 'some_other_scope',
    id => 'this is a fourth message',
    level => 'error',
    subject => 'verb',
    params => ['some_other_param']
});
is_deeply($c->message($msg2), bless({
    messages => [
      bless({
        level   => "info",
        msgid   => "this is a message",
        scope   => "some_scope",
        subject => "verb",
        params  => ["string_param", 10],
      }, "Message::Stack::Message"),
      bless({
        level   => "error",
        msgid   => "this is the second message",
        scope   => "some_scope",
        subject => "ruler",
      }, "Message::Stack::Message"),
      bless({
        level   => "info",
        msgid   => "this is a third message",
        scope   => "some_other_scope",
        subject => "ruler",
      }, "Message::Stack::Message"),
      bless({
        level   => "error",
        msgid   => "this is a fourth message",
        scope   => "some_other_scope",
        subject => "verb",
        params  => ["some_other_param"],
      }, "Message::Stack::Message"),
   ],
}, "Message::Stack"), 'Four messages in the stash');


isa_ok($c->message, 'Message::Stack', 'Returns a Message::Stack');
is($c->has_messages, 4, 'Four messages in the stack');

is($c->has_messages('some_other_scope'), 2, 'some_other_scope gets two messages');
is($c->reset_messages('some_other_scope'), 2, 'resetting the scope gets two messages');
is($c->reset_messages, 2, 'resetting the whole stack gets two messages');

is($c->has_messages, 0, 'No messages left in the stack');

is_deeply($c->message('This is the simple message interface'), bless({
    messages => [
      bless({
        level   => "success",
        msgid   => "This is the simple message interface",
        scope   => "global",
      }, "Message::Stack::Message"),
   ],
}, "Message::Stack"), 'One message in the stash, via the simple interface');

$c->config->{'Plugin::MessageStack'}->{stash_key} = "foo";
is($c->has_messages, 0, 'Changing the stash key hides the other messages');

$c->config->{'Plugin::MessageStack'}->{default_type} = "failure";

# change the stash key again to test the initialization for message()
$c->config->{'Plugin::MessageStack'}->{stash_key} = "bar";

is_deeply($c->message({ message => 'A message to test defaults and configuration options' }), bless({
    messages => [
      bless({
        level   => "failure",
        msgid   => "A message to test defaults and configuration options",
        scope   => "global",
      }, "Message::Stack::Message"),
   ],
}, "Message::Stack"), 'Changing the defaults via config');

is_deeply($c->message({ message => 'A second message to test defaults and configuration options' }), bless({
    messages => [
      bless({
        level   => "failure",
        msgid   => "A message to test defaults and configuration options",
        scope   => "global",
      }, "Message::Stack::Message"),
      bless({
        level   => "failure",
        msgid   => "A second message to test defaults and configuration options",
        scope   => "global",
      }, "Message::Stack::Message"),
   ],
}, "Message::Stack"), 'Adding messages with non-default configuration');

is_deeply($c->message({
    message => 'A third message to test defaults and configuration options',
    scope => 'not global'
}), bless({
    messages => [
      bless({
        level   => "failure",
        msgid   => "A message to test defaults and configuration options",
        scope   => "global",
      }, "Message::Stack::Message"),
      bless({
        level   => "failure",
        msgid   => "A second message to test defaults and configuration options",
        scope   => "global",
      }, "Message::Stack::Message"),
      bless({
        level   => "failure",
        msgid   => "A third message to test defaults and configuration options",
        scope   => "not global",
      }, "Message::Stack::Message"),
   ],
}, "Message::Stack"), 'Adding messages with non-default configuration and non-default params');

is($c->has_messages, 3, 'Three messages with the new stash key');
is($c->reset_messages('not global'), 1, 'Reseeting works with a custom stash key');

$c->config->{'Plugin::MessageStack'}->{model} = 'Messages';
is($c->has_messages, 2, "Setting the model doesn't change the current stack");

$c->config->{'Plugin::MessageStack'}->{stash_key} = "baz";
isa_ok($c->message, 'Message::Stack', 'New model/stash key returns a new Message::Stack');
is($c->has_messages, 0, "No messages in the new stack");

is_deeply($c->message({ message => 'A message for the stack we got from the model' }), bless({
    messages => [
     bless({
       level => "failure",
       msgid => "A message for the stack we got from the model",
       scope => "global",
     }, "Message::Stack::Message"),
   ],
}, "Message::Stack"), 'Adding message with a Message::Stack obtained from the model');

is_deeply($c->message({ message => 'And one without the default level', type => 'probably not failure' }), bless({
    messages => [
     bless({
       level => "failure",
       msgid => "A message for the stack we got from the model",
       scope => "global",
     }, "Message::Stack::Message"),
     bless({
       level => "probably not failure",
       msgid => "And one without the default level",
       scope => "global",
     }, "Message::Stack::Message"),
   ],
}, "Message::Stack"), 'Adding message with a Message::Stack obtained from the model and non-default values');

is($c->has_messages, 2, "New model has two message");
is($c->reset_messages, 2, "Clear out messages with a custom stash_key");

done_testing;
