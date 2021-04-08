use 5.012;
use warnings;
use Test::More;
use lib 't/lib'; use MyTest;

plan skip_all => 'set TEST_FULL=1 to enable real test coverage' unless $ENV{TEST_FULL};

catch_run("full-zones-8");

done_testing();
