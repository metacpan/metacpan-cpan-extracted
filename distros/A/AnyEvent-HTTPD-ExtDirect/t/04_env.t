use common::sense;

use Getopt::Long;

use RPC::ExtDirect::Test::Pkg::Env;

use lib 't/lib';
use RPC::ExtDirect::Test::Util::AnyEvent;
use RPC::ExtDirect::Test::Data::Env;

use AnyEvent::HTTPD::ExtDirect;

my ($host, $port) = ('127.0.0.1', 0);
GetOptions('host=s' => \$host, 'port=i' => \$port);

my $tests = RPC::ExtDirect::Test::Data::Env::get_tests;

run_tests($tests, $host, $port, @ARGV);
