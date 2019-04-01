use Arango::DB;
use Test2::V0;
use Test2::Tools::Exception qw/dies lives/;
do "./t/helper.pl";

skip_all "No ArangoDB environment variables for testing. See README" unless valid_env_vars();
skip_all "Can't reach ArangoDB Server" unless server_alive();

my $arango = Arango::DB->new( );
clean_test_environment($arango);

my $db = $arango->create_database("tmp_");

my $collection = $db->create_collection("collection");

my $documents = [
     { name => 'Fred Flinstone', gender => 'male' },
     { name => 'Wilma Flinstone', gender => 'female' },
     { name => 'Barney Rubble', gender => 'male' },
     { name => 'Betty Rubble', gender => 'female' },
     { name => 'Bamm-Bamm Rubble', gender => 'male' }
];
for my $doc (@$documents) {
    $collection->create_document( $doc );
}

my $list = $collection->document_paths();
is scalar(@$list), 5, "Five documents imported correctly";

my $query = q{FOR p IN collection LIMIT 2 RETURN p};
my $cursor = $db->cursor($query);

isa_ok $cursor, 'Arango::DB::Cursor';
ok exists($cursor->{result}) => 'Results key exists';
is scalar(@{$cursor->{result}}) => 2 => 'Correct number of hits';

$cursor = $db->cursor($query, count => 'true');
isa_ok $cursor, 'Arango::DB::Cursor';
ok exists($cursor->{count}) => 'Results count exists';

$arango->delete_database("tmp_");

done_testing;
