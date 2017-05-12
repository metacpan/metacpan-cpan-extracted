
use strict;
use warnings;

use App::OverWatch;

use lib 't', '.';
require 'lib.pl';
require 'servicelock.pl';

use Test::More;

eval {
    require DBD::SQLite;
};
if ($@) {
    plan skip_all => "Warning: Couldn't load DBD::SQLite - Skipping sqlite test";
}

use_ok("DBD::SQLite");

my $config = get_test_config('sqlite');
note $config;

my $ServiceLock = get_servicelock($config);

run_servicelock_tests($ServiceLock);

done_testing();
