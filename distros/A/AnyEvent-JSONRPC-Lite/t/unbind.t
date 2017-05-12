use Test::Base;
use Test::TCP;
use Test::Exception;

plan tests => 2;

use AnyEvent::JSONRPC::Lite;

my $port = empty_port;

{
	lives_ok {
		my $server = jsonrpc_server undef, $port;
	};
};

{
	lives_ok {
		my $server = jsonrpc_server undef, $port;
	};
}
