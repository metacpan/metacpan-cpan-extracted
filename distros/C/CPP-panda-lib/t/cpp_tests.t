use 5.012;
use warnings;
use lib 't/lib';
use Test::More qw/no_plan/;
use CPP::panda::lib;

my $full_tests = eval {
    package CPP::panda::lib;
    require Panda::XSLoader;
    Panda::XSLoader::bootstrap();
    1;
};

if ($full_tests) {
    ok (CPP::panda::lib::Test::test_run_all_cpp_tests());
} else {
    warn "rebuild Makefile.PL adding TEST_FULL=1 to enable all tests'" unless $full_tests;
    ok 1;
}

done_testing();