package MyApp;

use Dancer2;
use Dancer2::Plugin::RPC::JSONRPC;
use Dancer2::Plugin::RPC::RESTRPC;
use Dancer2::Plugin::RPC::XMLRPC;
use Dancer2::RPCPlugin::CallbackResult;

BEGIN {
    set(log => 'debug');
}

my $callback = sub {
    return callback_succes();
};

jsonrpc '/endpoint' => {
    publish   => 'pod',
    arguments => [qw/ MyAppCode /],
    callback  => $callback,
};

restrpc '/rest' => {
    publish   => 'pod',
    arguments => [qw/ MyAppCode /],
    callback  => $callback,
};

xmlrpc '/endpoint' => {
    publish   => 'pod',
    arguments => [qw/ MyAppCode /],
    callback  => $callback,
};

1;
