
use strict;
use warnings;

use App::OverWatch;

use lib 't', '.';
require 'lib.pl';
require 'servicelock.pl';

use Test::More;

eval {
    require DBD::mysql;
};
if ($@) {
    plan skip_all => "Warning: Couldn't load DBD::mysql - Skipping mysql test";
}

use_ok("DBD::mysql");

my $config = get_test_config('mysql');
note $config;

my $ServiceLock = get_servicelock($config);
my $DB = $ServiceLock->{DB};

## Remove any existing table
$DB->dbix_run("DROP TABLE IF EXISTS servicelocks");

run_servicelock_tests($ServiceLock);

## Remove the table
$DB->dbix_run("DROP TABLE servicelocks");

done_testing();
