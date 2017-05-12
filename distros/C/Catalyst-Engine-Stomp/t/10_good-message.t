use strict;
use warnings;
use Test::More;

# Tests which expect a STOMP server like ActiveMQ to exist on
# localhost:61613, which is what you get if you just get the ActiveMQ
# distro and changes its config.

use Net::Stomp;
use YAML::XS qw/ Dump Load /;
use Data::Dumper;

use FindBin;
use lib "$FindBin::Bin/lib";
use TestServer;

check_amq_broker();

plan tests => 22;

sub test_it {
    my ($destination) = @_;

    my $stomp = start_server();

    my $frame = $stomp->connect();
    ok($frame, 'connect to MQ server ok');

    my $reply_to = sprintf '%s:1', $frame->headers->{session};
    ok($frame->headers->{session}, 'got a session');
    ok(length $reply_to > 2, 'valid-looking reply_to queue');

    ok($stomp->subscribe( {
        destination => '/temp-queue/reply'
    } ),
       'subscribe to temp queue');

    my $message = {
        payload => { foo => 1, bar => 2 },
        reply_to => $reply_to,
        type => 'testaction',
    };
    my $text = Dump($message);
    ok($text, 'compose message');

    $stomp->send( { destination => $destination, body => $text } );

    my $reply_frame = $stomp->receive_frame();
    ok($reply_frame, 'got a reply');
    is($reply_frame->headers->{destination},
       "/remote-temp-queue/$reply_to",
       'came to correct temp queue');
    ok($reply_frame->body, 'has a body');

    my $response = Load($reply_frame->body);
    ok($response, 'YAML response ok');
    ok($response->{type} eq 'testaction_response', 'correct type');

    $stomp->disconnect;
    ok(!$stomp->socket->connected, 'disconnected');
}

note 'testing queues';
test_it('/queue/testcontroller');
note 'testing topics';
test_it('/topic/testcontroller');
