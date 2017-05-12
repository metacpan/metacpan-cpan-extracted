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
        my $client = mprpc_client('127.0.0.1', $port);
        my $ret = $client->call('sum' => [qw/1 2 3/])->recv;
        is $ret, 6;
        done_testing;
    },
);

