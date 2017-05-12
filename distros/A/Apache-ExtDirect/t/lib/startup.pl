use strict;
use warnings FATAL => 'all';
no  warnings 'uninitialized';

use RPC::ExtDirect::Test::Foo;
use RPC::ExtDirect::Test::Bar;
use RPC::ExtDirect::Test::Qux;
use RPC::ExtDirect::Test::PollProvider;
use RPC::ExtDirect::Test::JuiceBar;
use RPC::ExtDirect::Test::Env;

use RPC::ExtDirect::API api_path    => '/api',
                        router_path => '/router',
                        poll_path   => '/events';

use Apache::ExtDirect::API;
use Apache::ExtDirect::Router;
use Apache::ExtDirect::EventProvider;

# This is to produce consistent output
$Apache::ExtDirect::API::DEBUG           = 1;
$Apache::ExtDirect::Router::DEBUG        = 1;
$Apache::ExtDirect::EventProvider::DEBUG = 1;

$RPC::ExtDirect::Test::JuiceBar::CHEAT   = 1;

1;

