use Test::More;
use Test::MockObject;

plan tests => 12;

my $module = 'DB::CouchDB::Schema';

use_ok($module);
can_ok($module, qw/_mk_view_accessor load_schema_from_db
                   load_schema_from_script
                   /);

my $db = $module->new();

$db->_mk_view_accessor( { _id => '_design/foo', 
                          views => {bar => '"blah"',
                                    boo => '"Ahh!!"'
                                   }
                         }
                      );

can_ok($db, 'foo_bar', 'foo_boo');

$db->views()->{'foo_bar'} = sub { return 'fubar'; };

is($db->foo_bar(), 'fubar', 'the created method delegates properly');

can_ok($module, 'dump_whole_db');
{
    my $mocker = Test::MockObject->new();
    $mocker->mock(create_named_doc => sub {
        my $self = shift;
        my $doc = shift;
        my $name = shift;
        return DB::CouchDB::Result->new({ _id => $name, %$doc });
    });
    $mocker->mock(create_doc => sub {
        my $self = shift;
        my $doc = shift;
        return DB::CouchDB::Result->new({ _id => 'adoc', %$doc });
    });

    can_ok($module, 'create_doc');
    my $db = $module->new();
    $db->{server} = $mocker;
    ok($db->server == $mocker, 'the server is mocked');
    
    my $response = $db->create_doc( id => 'somedoc', doc => { foo => 'baz' } );
    is($response->{_id}, 'somedoc', 'create_doc with an id works');
    is($response->{foo}, 'baz', 'create_doc with an id has the doc attributes');

    my $response2 = $db->create_doc( doc => { foo => 'bar' } );
    is($response2->{_id}, 'adoc', 'create_doc without an id works');
    is($response2->{foo}, 'bar', 'create_doc without an id has the doc attributes');
    
    can_ok($module, 'create_new_db');
    

}
