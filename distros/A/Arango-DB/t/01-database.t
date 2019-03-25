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

    my $db = Arango::DB->new( );

    my $version = $db->version;
    is $version->{server} => 'arango';

    my $ans = $db->list_databases;

    is ref($ans), "ARRAY", "Databases list is an array";
    ok grep { /^_system$/ } @$ans, "System database is present";

    $ans = $db->create_database('tmp_');

    isa_ok($ans => "Arango::DB::Database");

    $ans = $db->list_databases;
    ok grep { /^tmp_$/ } @$ans, "tmp_ database was created";

    $db->delete_database('tmp_');

    $ans = $db->list_databases;
    ok !grep { /^tmp_$/ } @$ans, "tmp_ database was deleted";

    like(
        dies { my $system_db = $db->database("system"); },
        qr/Arango::DB.*Database not found/,
        "Got exception"
    );

    my $system = $db->database("_system");
    isa_ok($system => "Arango::DB::Database");

}
done_testing;
