# -*- cperl -*-
use Arango::Tango;
use Test2::V0;
use Test2::Tools::Exception qw/dies lives/;

do "./t/helper.pl";

skip_all "No ArangoDB environment variables for testing. See README" unless valid_env_vars();
skip_all "Can't reach ArangoDB Server" unless server_alive();

my $arango = Arango::Tango->new( );
skip_all "Credentials problems" unless auth_ok($arango);
clean_test_environment($arango);


my $db = $arango->create_database("tmp_");

my $test_collections = $db->list_collections;
is ref($test_collections), "ARRAY", "Collection list is still an array";
my $nr_db_collections = scalar(@$test_collections);

my $collection = $db->create_collection("collection");
isa_ok($collection => "Arango::Tango::Collection");

my $same_collection = $db->collection("collection");
isa_ok($collection => "Arango::Tango::Collection");

$test_collections = $db->list_collections;
is scalar(@$test_collections), $nr_db_collections+1;

my $info = $collection->info;
is ($info->{name}, "collection");

my $checksum = $collection->checksum;
ok exists($checksum->{checksum});
is $checksum->{type}, 2;

my $count = $collection->count;
is $count->{count}, 0;

my $figures = $collection->figures;
is $figures->{count}, 0;

my $ans = $collection->load;
is $ans->{name}, "collection";
is $ans->{type}, 2;

my %ttl_idx_opts = (
    type => 'ttl',
    name => 'idx',
    fields => ['t_x'],
    expireAfter => 3600
);

my $idx = $db->create_ttl_index("collection", %ttl_idx_opts);
ok !$idx->{error};
is $idx->{type}, 'ttl';
is $idx->{name}, 'idx';

my $idxs = $db->get_indexes("collection");
ok !$idxs->{error};
is $idxs->{code}, 200;
is $idxs->{indexes}->[0]->{name}, 'primary';
is $idxs->{indexes}->[0]->{type}, 'primary';
is $idxs->{indexes}->[1]->{name}, 'idx';
is $idxs->{indexes}->[1]->{type}, 'ttl';

$ans = $collection->load_indexes;
ok $ans->{result};

my $props = $collection->properties;
ok exists($props->{keyOptions});

my $rev = $collection->revision;
ok exists($rev->{revision});

can_ok $collection, "rotate";

$ans = $collection->unload;
is $ans->{name}, "collection";

$ans = $collection->set_properties(waitForSync => 0);
ok !$ans->{waitForSync};

$ans = $collection->set_properties(waitForSync => 1);
ok $ans->{waitForSync};

$ans = $collection->rename("newcollectionname");
is $ans->{name}, "newcollectionname";

# **Note:** this method is specific for the RocksDB storage engine
# $ans = $collection->recalculate_count;
# ok $ans->{result};

$db->delete_collection("newcollectionname");
like(
    dies { my $system_db = $db->collection("newcollectionname"); },
    qr/Arango::Tango.*Collection not found in database/,
    "Got exception"
);

$test_collections = $db->list_collections;
is scalar(@$test_collections), $nr_db_collections;

$arango->delete_database("tmp_");

done_testing;
