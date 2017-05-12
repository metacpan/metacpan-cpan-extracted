use Test::More;

plan tests => 29;
my $module = 'DB::CouchDB';

use_ok($module, 'the module is useable');

can_ok($module, 'new');
my $db = $module->new(host => 'localhost', db => 'foo');
is($db->{host}, 'localhost', 'the domain has been stored');
is($db->{port}, 5984, 'the port defaulted correctly');

can_ok($db, 'uri'); 
isa_ok($db->uri(), 'URI');

can_ok($db, '_uri_all_dbs');
is($db->_uri_all_dbs(), 'http://localhost:5984/_all_dbs', 'the all dbs uri is correct');

can_ok($db, '_uri_db');
is($db->_uri_db(), 'http://localhost:5984/foo', 'the db uri is correct');

can_ok($db, '_uri_db_docs');
is($db->_uri_db_docs(), 'http://localhost:5984/foo/_all_docs', 'the db all docs uri is correct');

can_ok($db, '_uri_db_doc');
is($db->_uri_db_doc('bar'), 'http://localhost:5984/foo/bar', 'the db doc uri is correct');

can_ok($db, '_uri_db_bulk_doc');
is($db->_uri_db_bulk_doc(), 'http://localhost:5984/foo/_bulk_docs', 'the db bulk doc uri is correct');

can_ok($db, '_uri_db_view');
is($db->_uri_db_view('bleh'), 'http://localhost:5984/foo/_view/bleh', 'the db bulk doc uri is correct');

can_ok($db, '_call');

isa_ok($db->json(), 'JSON');

ok(!$db->json()->get_allow_blessed, 'the json serializer allow_blessed defaults to true');
ok(!$db->json()->get_convert_blessed, 'the json serializer allow_blessed defaults to true');

can_ok($db, 'handle_blessed');
isa_ok($db->handle_blessed(1), 'DB::CouchDB'); 
ok($db->json()->get_allow_blessed, 'the json serializer allow_blessed is true');
ok($db->json()->get_convert_blessed, 'the json serializer allow_blessed is true');

$db->handle_blessed(0); 
ok(!$db->json()->get_allow_blessed, 'the json serializer allow_blessed is not true');
ok(!$db->json()->get_convert_blessed, 'the json serializer allow_blessed is not true');

can_ok($db, qw/all_dbs
               create_db
               delete_db
               create_doc
               update_doc
               delete_doc
               get_doc
               view
             /);
