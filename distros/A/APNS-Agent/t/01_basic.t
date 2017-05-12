use strict;
use warnings;
use utf8;
use Test::More 0.98;
use Test::TCP;
use Plack::Test;
use HTTP::Request::Common;

use AnyEvent;
use AnyEvent::Socket;

use JSON::XS;
use APNS::Agent;

my $cv = AnyEvent->condvar;

my $apns_port = empty_port;
tcp_server undef, $apns_port, sub {
    my $fh = shift or die $!;
    my $handle = AnyEvent::Handle->new(fh => $fh);

    $handle->push_read( chunk => 1, sub {
        is($_[1], pack('C', 1), 'command ok');

        $handle->push_read( chunk => 4, sub {
            is($_[1], pack('N', 1), 'identifier ok');

            $handle->push_read( chunk => 4, sub {
                my $expiry = unpack('N', $_[1]);
                my $diff = $expiry - (time() + 3600*24);

                ok 0 <= $diff && $diff < 5, 'expiry ok';

                $handle->push_read( chunk => 2, sub {
                    is($_[1], pack('n', 32), 'token size ok');

                    $handle->push_read( chunk => 32, sub {
                        is($_[1], 'd'x32, 'token ok');

                        $handle->push_read( chunk => 2, sub {
                            my $payload_length = unpack('n', $_[1]);

                            $handle->push_read( chunk => $payload_length, sub {
                                my $payload = $_[1];
                                my $p = decode_json($payload);

                                is(length $payload, $payload_length, 'payload length ok');
                                is $p->{aps}->{alert}, 'ほげ', 'value of alert';

                                $cv->send;
                            });
                        });
                    });
                });
            });
        });
    });
};

local $Log::Minimal::LOG_LEVEL = "NONE";

my $apns_agent = APNS::Agent->new(
    sandbox     => 1,
    certificate => 'dummy',
    private_key => 'dummy',
    debug_port  => $apns_port,
);

test_psgi
    app => $apns_agent->to_app,
    client => sub {
        my $cb  = shift;
        ok !$apns_agent->__apns->connected;

        my $req = POST 'http://localhost', [
            token => unpack("H*", 'd'x32),
            alert => 'ほげ',
        ];

        my $res = $cb->($req);
        like $res->content, qr/Accepted/;

        subtest 'monitor' => sub {
            my $req = GET 'http://localhost/monitor';

            my $res = $cb->($req);
            ok $res->is_success;
            my $result = decode_json($res->content);

            is $result->{sent}, 0;
            is $result->{queued}, 1;
        };

        $cv->recv;

        subtest 'monitor after sent' => sub {
            my $req = GET 'http://localhost/monitor';

            my $res = $cb->($req);
            ok $res->is_success;
            my $result = decode_json($res->content);

            is $result->{sent}, 1;
            is $result->{queued}, 0;
        };

        ok $apns_agent->__apns->connected;
        ok %{ $apns_agent->_sent_cache->{_entries} };
    };

done_testing;
