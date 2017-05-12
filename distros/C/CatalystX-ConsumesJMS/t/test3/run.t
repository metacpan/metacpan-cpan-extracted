#!perl
use warnings;
use Test::Most;
use Test::Fatal;
use Test::Plack::Handler::Stomp;
use Net::Stomp::Frame;
use Data::Printer;
use lib 't/lib';
use Test3;

my $t = Test::Plack::Handler::Stomp->new();
$t->set_arg(
    subscriptions => [
        { destination => '/queue/input_queue',
          path_info => '/input_queue', },
    ],
);
$t->clear_frames_to_receive;

my $app;
if (Test3->can('psgi_app')) {
    $app = Test3->psgi_app;
}
else {
    Test3->setup_engine('PSGI');
    $app = sub { Test3->run(@_) };
}
my $consumer = Test3->component('Test3::Foo::One');

subtest 'correct message' => sub {
    $t->queue_frame_to_receive(Net::Stomp::Frame->new({
        command => 'MESSAGE',
        headers => {
            destination => '/queue/input_queue',
            subscription => 0,
            'content-type' => 'json',
            type => 'my_type',
            'message-id' => 356,
        },
        body => '{"foo":"bar"}',
    }));

    my $e = exception { $t->handler->run($app) };
    is($e,undef, 'consuming the message lives')
        or note p $e;

    cmp_deeply($consumer->messages,
               [
                   [
                       isa('HTTP::Headers'),
                       { foo => 'bar' },
                   ],
               ],
               'message consumed & logged')
        or note p $consumer->messages;

    cmp_deeply($t->frames_sent,
               [
                   all(
                       isa('Net::Stomp::Frame'),
                       methods(
                           command=>'SEND',
                           body=>'{"no":"thing"}',
                           headers => {
                               destination => '/remote-temp-queue/reply-address',
                           },
                       )
                   ),
                   all(
                       isa('Net::Stomp::Frame'),
                       methods(
                           command=>'ACK',
                           body=>undef,
                           headers => {
                               'message-id' => 356,
                           },
                       )
                   ),
               ],
               'reply & ack sent');
    $t->clear_sent_frames;
};

# in the following two tests, we check that errors are *not* caught
# specially. Error handling is provided by a role that
# Test3::Base::Foo does not consume.
#
# actually, an application should never receive a message for a
# destination it didn't subscribe to...

# silence the expected error messages if the user does not want to see
# them
Test3->log->disable('error') unless $ENV{TEST_VERBOSE};

subtest 'wrong destination' => sub {
    $t->queue_frame_to_receive(Net::Stomp::Frame->new({
        command => 'MESSAGE',
        headers => {
            destination => '/queue/input_queue_wrong',
            subscription => 1,
            'content-type' => 'json',
            type => 'my_type',
            'message-id' => 358,
        },
        body => '{"foo":"bar"}',
    }));


    my $e = exception { $t->handler->run($app) };
    is($e,undef, 'consuming the message lives')
        or note p $e;

    cmp_deeply($t->frames_sent,
               [
                   all(
                       isa('Net::Stomp::Frame'),
                       methods(
                           command=>'ACK',
                           body=>undef,
                           headers => {
                               'message-id' => 358,
                           },
                       )
                   ),
               ],
               'ack sent');
    $t->clear_sent_frames;
};

subtest 'wrong type' => sub {
    $t->queue_frame_to_receive(Net::Stomp::Frame->new({
        command => 'MESSAGE',
        headers => {
            destination => '/queue/input_queue',
            subscription => 0,
            'content-type' => 'json',
            type => 'their_type',
            'message-id' => 359,
        },
        body => '{"foo":"bar"}',
    }));


    my $e = exception { $t->handler->run($app) };
    is($e,undef, 'consuming the message lives')
        or note p $e;

    cmp_deeply($t->frames_sent,
               [
                   all(
                       isa('Net::Stomp::Frame'),
                       methods(
                           command=>'ACK',
                           body=>undef,
                           headers => {
                               'message-id' => 359,
                           },
                       )
                   ),
               ],
               'ack sent');
    $t->clear_sent_frames;
};

done_testing();
