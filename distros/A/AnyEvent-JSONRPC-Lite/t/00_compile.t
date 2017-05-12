use strict;
use Test::More tests => 4;

BEGIN {
    use_ok 'AnyEvent::JSONRPC::Lite';
    use_ok 'AnyEvent::JSONRPC::Lite::Client';
    use_ok 'AnyEvent::JSONRPC::Lite::Server';
    use_ok 'AnyEvent::JSONRPC::Lite::CondVar';
}
