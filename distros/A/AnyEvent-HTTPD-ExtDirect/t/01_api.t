use common::sense;

use Getopt::Long;

use RPC::ExtDirect::Test::Pkg::Foo;
use RPC::ExtDirect::Test::Pkg::Bar;
use RPC::ExtDirect::Test::Pkg::Qux;
use RPC::ExtDirect::Test::Pkg::PollProvider;
use RPC::ExtDirect::Test::Pkg::Meta;

use lib 't/lib';
use RPC::ExtDirect::Test::Util::AnyEvent;
use RPC::ExtDirect::Test::Data::API;

use AnyEvent::HTTPD::ExtDirect;

my ($host, $port) = ('127.0.0.1', 0);
GetOptions('host=s' => \$host, 'port=i' => \$port);

my $tests = RPC::ExtDirect::Test::Data::API::get_tests;

run_tests($tests, $host, $port, @ARGV);
