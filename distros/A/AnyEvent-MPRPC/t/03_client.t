use strict;
use warnings;
use Test::TCP;
use AnyEvent;
use AnyEvent::MPRPC;
use Test::More;

test_tcp(
    server => sub {
        my $port = shift;
        my $w = AnyEvent->signal( signal => 'PIPE', cb => sub { warn "SIGPIPE" } );

        my $server = AnyEvent::MPRPC::Server->new(host => '127.0.0.1', port => $port, on_error => sub {});
        $server->reg_cb(
            sum => sub {
                my ($res_cv, $args) = @_;
                my $i = 0;
                $i += $_ for @$args;
                $res_cv->result( $i );
            },
        );
        AnyEvent->condvar->recv;
    },
    client => sub {
        my $port = shift;
        my $cvp = AE::cv();
        my $cvc = AE::cv();
        my $client = AnyEvent::MPRPC::Client->new(
            host => '127.0.0.1',
            port => $port,
            before_connect => sub {
                $cvp->send('connecting');
            },
            after_connect  => sub {
                $cvc->send('connected');
            },
        );
        is $cvp->recv(), 'connecting', "connecting";
        is $cvc->recv(), 'connected', "connected";
        my $ret = $client->call('sum' => [qw/1 2 3/])->recv;
        is $ret, 6, 'pass params as ArrayRef';

        $ret = $client->call('sum' => (1..10))->recv;
        is $ret, 55, 'pass params as Array';

        $ret = $client->call('sum' => 1)->recv;
        is $ret, 1, 'pass one param';

        done_testing;
    },
);
