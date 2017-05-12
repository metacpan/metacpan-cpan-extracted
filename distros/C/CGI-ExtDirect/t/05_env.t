use strict;
use warnings;

use lib 't/lib';
use RPC::ExtDirect::Test::Util::CGI;
use RPC::ExtDirect::Test::Data::Env;

use CGI::ExtDirect;

my $tests = RPC::ExtDirect::Test::Data::Env::get_tests;

run_tests($tests, @ARGV);
