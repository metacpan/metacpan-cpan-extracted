#!perl
use warnings;
use Test::Most;
use Test::Fatal;
use Test::Plack::Handler::Stomp;
use Net::Stomp::Frame;
use Data::Printer;
use lib 't/lib';

$ENV{CATALYST_CONFIG} = 't/lib/test3.conf';
require Test3;

# let's get the destinations from the controllers, to make sure they
# got created properly, 2 controllers for a single Foo, because of the
# configuration
my @destinations =
    map { '/'.$_ }
    grep { m{^(queue|topic)}x }
    map { Test3->controller($_)->action_namespace }
    Test3->controllers;

my $t = Test::Plack::Handler::Stomp->new();
$t->set_arg(
    subscriptions => [
        map { +{ destination => $_ } } @destinations,
    ],
);
$t->clear_frames_to_receive;
$t->clear_sent_frames;

my $app;
if (Test3->can('psgi_app')) {
    $app = Test3->psgi_app;
}
else {
    Test3->setup_engine('PSGI');
    $app = sub { Test3->run(@_) };
}
my $consumer = Test3->component('Test3::Foo::One');

sub run_test {
    my ($dest,$type) = @_;

    my $code = time();

    $consumer->messages([]);

    $t->queue_frame_to_receive(Net::Stomp::Frame->new({
        command => 'MESSAGE',
        headers => {
            destination => $dest,
            'content-type' => 'json',
            type => $type,
            'message-id' => $code,
        },
        body => qq{{"foo":"$dest","bar":"$type"}},
    }));

    my $e = exception { $t->handler->run($app) };
    is($e,undef, 'consuming the message lives')
        or note p $e;

    cmp_deeply($consumer->messages,
               [
                   [
                       isa('HTTP::Headers'),
                       { foo => $dest, bar => $type },
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
                               'message-id' => $code,
                           },
                       )
                   ),
               ],
               'reply & ack sent');
    $t->clear_sent_frames;
}

subtest 'message on a configured destination' => sub {
    run_test('/queue/input1','my_type');
};

subtest 'message on the other configured destination' => sub {
    run_test('/queue/input2','type1');
    run_test('/queue/input2','type2');
};

done_testing();
