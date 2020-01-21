use 5.012;
use warnings;
use Test::More;
use Test::Catch;
use lib 't/lib'; use MyTest;

XS::Loader::load('MyTest');
catch_run('api');

done_testing();
