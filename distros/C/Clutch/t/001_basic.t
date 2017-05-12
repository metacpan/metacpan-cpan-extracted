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
        my $client = Clutch::Client->new(
            servers => ['127.0.0.1:'.$port]
        );

        my $res;
        {
            $res = $client->request('function_name', 'args');
            note $res;
            is_deeply $res, +{response => 'args'};
        }

        {
            $res = $client->request('function_name', +{name => 'nekokak'});
            note $res;
            is_deeply $res, +{response => +{name => 'nekokak'}};
        }

        {
            $res = $client->request('foo', 'args');
            note $res;
            ok not $res;
        }

        {
            $res = $client->request('func', 'not_found');
            note $res;
            is $res, 'ERROR: unknow function';
        }

        kill 'TERM', $server_pid;
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

