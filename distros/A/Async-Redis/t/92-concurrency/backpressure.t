use strict;
use warnings;
use Test2::V0;
use Async::Redis;

subtest 'message_queue_depth default is 1' => sub {
    my $c = Async::Redis->new(host => 'x', port => 1);
    is $c->{message_queue_depth}, 1, 'default 1';
};

subtest 'explicit message_queue_depth preserved' => sub {
    my $c = Async::Redis->new(host => 'x', port => 1, message_queue_depth => 5);
    is $c->{message_queue_depth}, 5;
};

subtest 'message_queue_depth < 1 dies at construction' => sub {
    my $died = eval {
        Async::Redis->new(host => 'x', port => 1, message_queue_depth => 0);
        0;
    } || $@;
    ok $died, 'depth 0 rejected';
    like $died, qr/message_queue_depth/, 'error mentions the option';

    my $died2 = eval {
        Async::Redis->new(host => 'x', port => 1, message_queue_depth => -3);
        0;
    } || $@;
    ok $died2, 'negative depth rejected';
};

done_testing;
