use strict;
use Test::More tests => 6;

BEGIN {
    use_ok 'AnyEvent::JSONRPC';
    use_ok 'AnyEvent::JSONRPC::TCP::Client';
    use_ok 'AnyEvent::JSONRPC::TCP::Server';
    use_ok 'AnyEvent::JSONRPC::HTTP::Client';
    use_ok 'AnyEvent::JSONRPC::HTTP::Server';
    use_ok 'AnyEvent::JSONRPC::CondVar';
}
