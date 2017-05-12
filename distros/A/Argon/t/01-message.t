use strict;
use warnings;
use Test::More;
use Argon qw(:commands :priorities);

use_ok('Argon::Message');

my $msg = new_ok('Argon::Message', [cmd => $CMD_PING, pri => $PRI_HIGH, payload => ['blue', 42, { foo => 'bar'}]]);
ok($msg->id, 'msg id automatically created');

subtest 'encode <-> decode' => sub {
    my $decoded = Argon::Message->decode($msg->encode);
    is($decoded->id,  $msg->id,  'encode <-> decode (id)');
    is($decoded->cmd, $msg->cmd, 'encode <-> decode (cmd)');
    is($decoded->pri, $msg->pri, 'encode <-> decode (pri)');
    is_deeply($decoded->payload, $msg->payload, 'encode <-> decode (payload)');
};

subtest 'reply' => sub {
    my $reply = $msg->reply(cmd => $CMD_ACK, payload => undef);
    is($reply->id,  $msg->id,  'id copied');
    is($reply->pri, $msg->pri, 'pri copied');
    is($reply->cmd, $CMD_ACK,  'cmd overridden');
    ok(!defined $reply->payload, 'payload overridden with undef');
};

eval { Argon::Message->new(pri => $PRI_HIGH, payload => ['blue', 42, { foo => 'bar'}]) };
ok($@, 'new message without cmd fails');

done_testing;
