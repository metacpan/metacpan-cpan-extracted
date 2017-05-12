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

#plan tests => 24;

sub test_it {
    my ($type,$value) = @_;

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
        type => $type,
    };
    my $text = Dump($message);
    ok($text, 'compose message');

    $stomp->send( {
        destination => '/queue/newstyle',
        'custom_header' => $value,
        JMSType => $type,
        body => $text,
    } );

    my $reply_frame = $stomp->receive_frame();
    ok($reply_frame, 'got a reply');
    is($reply_frame->headers->{destination},
       "/remote-temp-queue/$reply_to",
       'came to correct temp queue');
    ok($reply_frame->body, 'has a body');

    my $response = Load($reply_frame->body);
    ok($response, 'YAML response ok');
    is($response->{type},
       "${type}_response",
       'correct type');
    is($response->{from},
       "newstyle$value",
       'correct controller');

    $stomp->disconnect;
    ok(!$stomp->socket->connected, 'disconnected');
}

note 'testing 1';
test_it('testaction','1');
note 'testing 2';
test_it('testaction','2');

note 'testing foo';
test_it('test_foo','1');
note 'testing bar';
test_it('test_bar','2');

done_testing();
