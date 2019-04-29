# -*- cperl -*-
use Arango::Tango;
use Test2::V0;
use Test2::Tools::Exception qw/dies lives/;

do "./t/helper.pl";

skip_all "No ArangoDB environment variables for testing. See README" unless valid_env_vars();
skip_all "Can't reach ArangoDB Server" unless server_alive(); 

my $arango = Arango::Tango->new( );
clean_test_environment($arango);

## -- version
my $version = $arango->version;
is $version->{server} => 'arango';

$version = $arango->version( details => 1 );
ok (exists($version->{details}));

$version = $arango->version( details => 0 );
ok (!exists($version->{details}));

## -- status
my $status = $arango->status;
is $status->{server} => 'arango';

## -- time
my $time = $arango->time;
like $time->{time}, qr/^\d+(?:\.\d+)?$/;

## -- statistics
my $stats = $arango->statistics;
like $stats->{time}, qr/^\d+(?:\.\d+)?$/;
like $stats->{http}{requestsTotal}, qr/^\d+$/;

my $stats_desc = $arango->statistics_description;
ok exists($stats_desc->{groups});
is ref($stats_desc->{groups}), "ARRAY";

## -- target version

my $target_version = $arango->target_version;
ok exists($target_version->{version});

## -- logs

my $logs = $arango->log;
ok exists($logs->{level});

my $log_level = $arango->log_level;
ok exists($log_level->{config});

## -- availability

my $availability = $arango->server_availability;
ok !$availability->{error};
ok exists($availability->{mode});

my $mode = $arango->server_mode;
ok !$mode->{error};
ok exists($mode->{mode});

## --- Cluster mode

my $id = eval { $arango->server_id };
SKIP: {
    skip "Not running in cluster mode" if $@ =~ /Internal Server Error/;

    is ref($id), "HASH"; ## not sure, until some cluster user can confirm me

    my $eps = $arango->cluster_endpoints;
    ok exists($eps->{endpoints}); ## not sure, until some cluster user can confirm me
}

my $role = $arango->server_role;
ok !$role->{error};

### engine

my $engine = $arango->engine;
like $engine->{name}, qr/^(mmfiles|rocksdb)$/;


## ---

my $ans = $arango->list_databases;

is ref($ans), "ARRAY", "Databases list is an array";
ok grep { /^_system$/ } @$ans, "System database is present";

$ans = $arango->create_database('tmp_');

isa_ok($ans => "Arango::Tango::Database");

$ans = $arango->list_databases;
ok grep { /^tmp_$/ } @$ans, "tmp_ database was created";

$arango->delete_database('tmp_');

$ans = $arango->list_databases;
ok !grep { /^tmp_$/ } @$ans, "tmp_ database was deleted";

like(
    dies { my $system_db = $arango->database("system"); },
    qr/Arango::Tango.*Database not found/,
    "Got exception"
);

my $system = $arango->database("_system");
isa_ok($system => "Arango::Tango::Database");

my $db = $arango->create_database('tmp_');  ## Recreate for more tests
$ans = $arango->list_databases;
ok grep { /^tmp_$/ } @$ans, "tmp_ database was created";

$db->delete;  ## Delete database using method.
$ans = $arango->list_databases;
ok !grep { /^tmp_$/ } @$ans, "tmp_ database was deleted";


done_testing;
