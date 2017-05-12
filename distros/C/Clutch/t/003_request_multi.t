use strict;
use warnings;
use lib './t/lib';
use Test::More;
use Test::TCP;
use Clutch::Client;
use Worker;

test_tcp(
    client => sub {
        my ($port, $server_pid) = @_;

        test_tcp(
            client => sub {
                my ($port2, $server_pid2) = @_;
                my $client = Clutch::Client->new(
                    servers => ['127.0.0.1:'.$port, '127.0.0.1:'.$port2],
                );

                my $res;
                {
                    $res = $client->request_multi([+{function => 'function_name', args => 'args1'}, +{function => 'function_name', args => 'args2'}]);
                    note explain $res;
                    is_deeply $res, [+{response => 'args1'},+{response => 'args2'}];
                }

                {
                    $res = $client->request_multi([+{function => 'function_rand', args => 'args1'}, +{function => 'function_rand', args => 'args2'}]);
                    note explain $res;
                    is_deeply $res, [+{response => 'args1'},+{response => 'args2'}];
                }

                kill 'TERM', $server_pid, $server_pid2;
            },
            server => sub {
                my $port = shift;
                Worker->new(
                    {
                        address => '127.0.0.1:'.$port,
                    }
                )->run();
            },
        );
    },
    server => sub {
        my $port = shift;
        Worker->new(
            {
                address => '127.0.0.1:'.$port,
            }
        )->run();
    },
);

done_testing;

