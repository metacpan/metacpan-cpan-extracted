use 5.012;
use warnings;
use Test::More;
use lib 't/lib'; use MyTest;

catch_run("[time-leapzone]");

done_testing();
