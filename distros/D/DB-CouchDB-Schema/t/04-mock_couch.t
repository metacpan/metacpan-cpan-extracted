use Test::More;
use Test::Exception;
use DB::CouchDB::Schema;

plan tests => 17;

my $module = 'Test::Mock::CouchDBSchema';
my $db_module = 'DB::CouchDB::Schema';

use_ok( $module );

can_ok( $module, 'mocked_views', 'mocked_docs', 'mock_schema', );

can_ok( $module, 'mock_view', 'mock_doc' );

my $mocker = mock_factory()->mock_view( 'foo_bar', mock_result_factory() ); 

isa_ok( $mocker, $module );

can_ok( $db_module, 'foo_bar' );
isa_ok( $db_module->foo_bar(), 'DB::CouchDB::Iter', 
    'successfully mocked view.return ' );

is_deeply( $db_module->foo_bar()->next_for_key('bar'), 
    mock_result_factory()->[1]{value}[0], 
    'the fist bar value is the mocked return' );

is( ref $mocker->mocked_views()->{'foo_bar'}, 'CODE', 
    'the the mocked method is registered' ); 

can_ok( $module, 'unmock_view', 'unmock_all_views' );

$mocker = $mocker->unmock_view('foo_bar');

isa_ok($mocker, $module);

ok( ref $mocker->mocked_views()->{'foo_bar'} ne 'CODE', 
    'the the mocked method is no longer registered' ); 

ok(!$db_module->can('foo_bar'), 'the view is no longer mocked');

dies_ok { $mocker->unmock('foo_bar'); } 
    'attempt to unmock a method that is not mocked dies';

my $db = $db_module->new(host => 'localhost', db => 'metabase');

my $schema = $db->schema();

is( $schema, $mocker->mock_schema(), 
    'our schema is the same as the mock schema' );

$mocker->mock_doc( 'somedoc' => { _id => 'somedoc', _rev => '1283505' } );

is_deeply( $db->get('somedoc'), { _id => 'somedoc', _rev => '1283505' },
    'successfully mocked a document call');

can_ok( $module, 'unmock_doc', 'unmock_all_docs' );
$mocker->unmock_doc( 'somedoc' );
is_deeply( $db->get('somedoc'), DB::CouchDB::Result->new({}), 
    'successfully unmocked the doc' );

# factories for generating test data
sub mock_factory {
    return Test::Mock::CouchDBSchema->new();
}

sub mock_result_factory {
    return [ { key => 'foo', value => [ { _id => 'fubar' } ] },
             { key => 'bar', value => [ { _id => 'barfu' } ] },
           ];
}


