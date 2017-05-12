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
            servers => ['127.0.0.1:'.$port],
        );

        my $res;
        {
            $res = $client->request_background_multi([+{function => 'function_name', args => 'args1'}, +{function => 'function_name', args => 'args2'}]);
            note explain $res;
            is_deeply $res, [qw/OK OK/];
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

