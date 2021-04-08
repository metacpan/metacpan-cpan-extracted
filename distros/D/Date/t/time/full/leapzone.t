use 5.012;
use warnings;
use Test::More;
use Test::Deep;
use lib 't/lib'; use MyTest;

plan skip_all => 'set TEST_FULL=1 to enable real test coverage' unless $ENV{TEST_FULL};

catch_run("full-leapzone");

done_testing();
