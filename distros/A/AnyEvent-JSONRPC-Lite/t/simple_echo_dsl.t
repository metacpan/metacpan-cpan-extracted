use Test::Base;

plan tests => 3;

use Test::TCP;
use AnyEvent::JSONRPC::Lite;

my $port = empty_port;

my $server = jsonrpc_server undef, $port;
$server->reg_cb(
    echo => sub {
        my ($result_cv, @params) = @_;
        ok("Echo called ok");
        is_deeply({ foo => 'bar' }, $params[0], 'echo param ok');
        $result_cv->result(@params);
    }
);

# client;
my $client = jsonrpc_client '127.0.0.1', $port;

my $res = $client->call( echo => { foo => 'bar' } )->recv;

is_deeply({ foo => 'bar' }, $res, 'echo response ok');



