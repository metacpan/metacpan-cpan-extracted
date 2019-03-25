use Arango::DB;
use Test2::V0;
use Test2::Tools::Exception qw/dies lives/;

do "./t/helper.pl";

skip_all "No ArangoDB environment variables for testing. See README" unless valid_env_vars();
skip_all "Can't reach ArangoDB Server" unless server_alive();

my $arango = Arango::DB->new( );
clean_test_environment($arango);

my $collections = $arango->list_collections;

is ref($collections), "ARRAY", "Collection list is an array";

my $db = $arango->create_database("tmp_");

my $test_collections = $db->list_collections;

is ref($test_collections), "ARRAY", "Collection list is still an array";

my $nr_system_collections = scalar(@$test_collections);

my $collection = $db->create_collection("collection");
isa_ok($collection => "Arango::DB::Collection");

my $same_collection = $db->collection("collection");
isa_ok($collection => "Arango::DB::Collection");

$test_collections = $db->list_collections;
is scalar(@$test_collections), $nr_system_collections+1;

$db->delete_collection("collection");

like(  
    dies { my $system_db = $db->collection("collection"); },
    qr/Arango::DB.*Collection not found in database/,
    "Got exception"
);

$test_collections = $db->list_collections;
is scalar(@$test_collections), $nr_system_collections;

$arango->delete_database("tmp_");

done_testing;
