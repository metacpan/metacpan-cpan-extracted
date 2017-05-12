use strict;
use warnings;

use lib 't/lib';
use RPC::ExtDirect::Test::Util::CGI;
use RPC::ExtDirect::Test::Data::Router;

use CGI::ExtDirect;

my $tests = RPC::ExtDirect::Test::Data::Router::get_tests;

run_tests($tests, @ARGV);
