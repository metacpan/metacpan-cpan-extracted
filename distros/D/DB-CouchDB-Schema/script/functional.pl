use DB::CouchDB;

my $conn = DB::CouchDB->new(host => 'localhost');

my $resp = $conn->create_db('mb_test');
print "create db response is: ", $/, $conn->json()->encode($resp), $/;

my $resp = $conn->create_doc('mb_test', {foo => 'bar'});
print "create doc response is: ", $/, $conn->json()->encode($resp), $/;
my $respObj = $resp;
my $id = $respObj->{id};
$resp = $conn->get_doc('mb_test', $id);
print "get response is: ", $/, $conn->json()->encode($resp), $/;
$respObj = $resp;

$respObj->{bleh} = 'blah';

$resp = $conn->update_doc('mb_test', $id, $respObj);
print "update response is: ", $/, $conn->json()->encode($resp), $/;
$respObj = $resp;

$resp = $conn->get_doc('mb_test', $id);
print "final get doc response is: ", $/, $conn->json()->encode($resp), $/;
my $rev = $resp->{_rev};
$resp = $conn->all_dbs();
print "all dbs response is: ", $/, $conn->json()->encode($resp), $/;

$resp = $conn->db_info('mb_test');
print "viewing the db response is: ", $/, $conn->json()->encode($resp), $/;
$resp = $conn->delete_doc('mb_test', $id, $rev);
print "delete doc response is: ", $/, $conn->json()->encode($resp), $/;

$resp = $conn->delete_db('mb_test');
print "delete db response is: ", $/, $conn->json()->encode($resp), $/;


