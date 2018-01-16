use 5.012;
use warnings;
use lib 't/lib';
use PLTest 'full';
use CPP::panda::lib qw/test_run_all_cpp_tests/;

ok (CPP::panda::lib::Test::test_run_all_cpp_tests());

done_testing();