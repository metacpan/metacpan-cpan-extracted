use Arango::DB;
use Test2::V0;
use Test2::Tools::Exception qw/dies lives/;
use HTTP::Tiny;

SKIP: {
    skip "No ArangoDB environment variables for testing. See README" unless defined $ENV{ARANGO_DB_HOST} 
                                                                        and defined $ENV{ARANGO_DB_USERNAME}
                                                                        and defined $ENV{ARANGO_DB_PASSWORD};

    my $port = $ENV{ARANGO_DB_PORT} || 8529;
    skip "Can't reach ArangoDB Server" unless HTTP::Tiny->new->get("http://$ENV{ARANGO_DB_HOST}:$port")->{success};

    my $arango = Arango::DB->new( );

    my $collections = $arango->list_collections;

    is ref($collections), "ARRAY", "Collection list is an array";

    my $db = $arango->create_database("tmp_");


    my $test_collections = $db->list_collections;

    is ref($test_collections), "ARRAY", "Collection list is still an array";

    my $nr_system_collections = scalar(@$test_collections);

    my $collection = $db->create_collection("collection");
    isa_ok($collection => "Arango::DB::Collection");


    $test_collections = $db->list_collections;
    is scalar(@$test_collections), $nr_system_collections+1;

    $db->delete_collection("collection");

    $test_collections = $db->list_collections;
    is scalar(@$test_collections), $nr_system_collections;

    $arango->delete_database("tmp_");
}

done_testing;