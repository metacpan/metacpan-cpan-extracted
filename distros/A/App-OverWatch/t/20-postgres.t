
use strict;
use warnings;

use App::OverWatch;

use lib 't', '.';
require 'lib.pl';
require 'servicelock.pl';

use Test::More;

eval {
    require DBD::Pg;
};
if ($@) {
    plan skip_all => "Warning: Couldn't load DBD::Pg - Skipping postgres test";
}

my $config = get_test_config('postgres');
if (!$config) {
    plan skip_all => "No postgres.conf found - Skipping DB test";
}

use_ok("DBD::Pg");

my $ServiceLock = get_servicelock($config);
my $DB = $ServiceLock->{DB};

## Remove any existing table
$DB->dbix_run("DROP TABLE IF EXISTS servicelocks");
$DB->dbix_run("DROP TYPE IF EXISTS lock_status");

run_servicelock_tests($ServiceLock);

## Remove the table
#$DB->dbix_run("DROP TABLE servicelocks");
#$DB->dbix_run("DROP TYPE lock_status");

done_testing();
