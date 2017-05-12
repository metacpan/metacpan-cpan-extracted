#!perl
use warnings;
use Test::Most;
use Test::Fatal;
use Test::Plack::Handler::Stomp;
use Net::Stomp::Frame;
use Data::Printer;
use lib 't/lib';
use Test4;

my $t = Test::Plack::Handler::Stomp->new();
$t->set_arg(
    subscriptions => [
        { destination => '/queue/input_queue',
          path_info => '/input_queue', },
    ],
);
$t->clear_frames_to_receive;

my $app;
if (Test4->can('psgi_app')) {
    $app = Test4->psgi_app;
}
else {
    Test4->setup_engine('PSGI');
    $app = sub { Test4->run(@_) };
}
my $consumer = Test4->component('Test4::Foo::One');

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
                           command=>'SEND',
                           body=>'{"default":"response"}',
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
                               'message-id' => 359,
                           },
                       )
                   ),
               ],
               'default response & ack sent');
    $t->clear_sent_frames;
};

done_testing();
