use 5.012;
use warnings;
use lib 't/lib';
use Test::More;
use CPP::panda::lib;

plan skip_all => 'rebuild Makefile.PL adding TEST_FULL=1 to enable all tests' unless eval {
    package CPP::panda::lib;
    require Panda::XSLoader;
    Panda::XSLoader::bootstrap();
    1;
};

ok (CPP::panda::lib::Test::test_run_all_cpp_tests());

done_testing();