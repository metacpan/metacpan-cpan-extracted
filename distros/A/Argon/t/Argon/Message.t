use Test2::Bundle::Extended;
use Argon::Constants qw(:commands :priorities);
use Argon::Message;

subtest 'reply' => sub {
  ok my $msg = Argon::Message->new(cmd => $QUEUE, info => 'info'), 'new';
  isnt $msg->reply(cmd => $DONE), $msg, 'reply != msg';
  is $msg->reply->id, $msg->id, 'reply retains id';
};

subtest 'tokens' => sub {
  ok my $msg = Argon::Message->new(cmd => $PING, token => 'test-token'), 'new';
  isnt $msg->error('foo')->token, $msg->token, 'error drops existing token';
  isnt $msg->reply->token, $msg->token, 'reply drops existing token';
  is $msg->reply(token => 'different-token')->token, 'different-token', 'reply allows setting token';
};

subtest 'results + predicates' => sub {
  subtest 'error' => sub {
    my $err = Argon::Message->new(cmd => $ERROR, info => 'error message');
    ok $err->failed, 'failed';
    ok dies { $err->result }, 'result';
  };

  subtest 'denied' => sub {
    my $denied = Argon::Message->new(cmd => $DENY, info => 'notice');
    ok $denied->denied, 'denied';
    ok dies { $denied->result }, 'result';
  };

  subtest 'done' => sub {
    my $done = Argon::Message->new(cmd => $DONE, info => 'result value');
    ok !$done->failed, '!failed';
    ok !$done->denied, '!denied';
    ok !dies { $done->result }, 'result';
  };
};

done_testing;
