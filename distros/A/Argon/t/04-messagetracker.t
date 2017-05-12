use strict;
use warnings;
use Test::More;
use Argon::Message;
use Argon qw(:commands);

my $class = 'Argon::MessageTracker';

use_ok($class) or BAIL_OUT;
my $tracker = new_ok($class) or BAIL_OUT;

my $msg   = Argon::Message->new(cmd => $CMD_QUEUE);
my $msgid = $msg->id;

ok(!$tracker->is_tracked($msgid), 'is_tracked false for invalid msgid');

$tracker->track_message($msgid);
ok($tracker->is_tracked($msgid), 'new message is tracked');

$tracker->complete_message($msg->reply(cmd => $CMD_ACK, payload => 42));
ok($tracker->is_tracked($msgid), 'completed message is tracked');
ok($tracker->is_complete($msgid), 'completed message is complete');

my $result = $tracker->collect_message($msgid);
is($result->payload, 42, 'correct reply returned');
ok(!$tracker->is_tracked($msgid), 'is_tracked false after collection');
ok(!$tracker->is_complete($msgid), 'is_complete false after collection');

done_testing;
