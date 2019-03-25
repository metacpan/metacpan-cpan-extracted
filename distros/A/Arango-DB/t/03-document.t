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

    my $db = $arango->create_database("tmp_");
    my $collection = $db->create_collection("collection");

    $collection->create_document( { Hello => 'World' });

    my $list = $collection->document_paths();

    is ref($list) => "ARRAY" => "List of paths is an array";
    like $list->[0] => qr!/_db/tmp_/_api/document/collection/\d+! => "path looks right";

    $arango->delete_database("tmp_");

}
done_testing;