use Test::Base;
use Test::TCP;

plan tests => 2;

my $port = empty_port;

use AnyEvent::JSONRPC::Lite;

my $server = jsonrpc_server undef, $port;
$server->reg_cb( error => sub {
    shift->error('error message!');
});

my $client = jsonrpc_client '127.0.0.1', $port;

my $res;
eval { $res = $client->call('error')->recv };

ok !$res, '$res is not set ok';
like $@, qr/^error message! at /, 'error message ok';
