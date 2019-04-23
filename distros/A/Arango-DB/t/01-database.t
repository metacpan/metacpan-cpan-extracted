# -*- cperl -*-
use Arango::DB;
use Test2::V0;
use Test2::Tools::Exception qw/dies lives/;

do "./t/helper.pl";

skip_all "No ArangoDB environment variables for testing. See README" unless valid_env_vars();
skip_all "Can't reach ArangoDB Server" unless server_alive(); 

my $arango = Arango::DB->new( );
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


my $ans = $arango->list_databases;

is ref($ans), "ARRAY", "Databases list is an array";
ok grep { /^_system$/ } @$ans, "System database is present";

$ans = $arango->create_database('tmp_');

isa_ok($ans => "Arango::DB::Database");

$ans = $arango->list_databases;
ok grep { /^tmp_$/ } @$ans, "tmp_ database was created";

$arango->delete_database('tmp_');

$ans = $arango->list_databases;
ok !grep { /^tmp_$/ } @$ans, "tmp_ database was deleted";

like(
    dies { my $system_db = $arango->database("system"); },
    qr/Arango::DB.*Database not found/,
    "Got exception"
);

my $system = $arango->database("_system");
isa_ok($system => "Arango::DB::Database");

done_testing;
