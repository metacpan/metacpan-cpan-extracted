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

$collection->create_document( { Hello => 'World' });

my $list = $collection->document_paths();

is ref($list) => "ARRAY" => "List of paths is an array";
like $list->[0] => qr!/_db/tmp_/_api/document/collection/\d+! => "path looks right";

$arango->delete_database("tmp_");

done_testing;
