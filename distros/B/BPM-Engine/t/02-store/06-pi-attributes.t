use strict;
use warnings;
use Test::More;
use Test::Fatal;
use t::TestUtils;

my $schema = schema();
my $package = $schema->resultset('Package')->create({});
my $process = $schema->resultset('Process')->create({ package_id => $package->id });

#-- create

my $rs = $schema->resultset('ProcessInstanceAttribute');
isa_ok(exception { $rs->create() }, 'DBIx::Class::Exception');
like(  exception { $rs->create() }, qr/create needs a hashref/);
# mysql: execute failed: Field 'process_instance' doesn't have a default value
isa_ok(exception { $rs->create({}) }, 'DBIx::Class::Exception');
#like(  exception { $rs->create({}) }, qr/process_instance_id may not be NULL/);
# mysql: execute failed: Field 'name' doesn't have a default value
isa_ok(exception { $rs->create({ process_instance_id => 1 }) }, 'DBIx::Class::Exception');
#like(  exception { $rs->create({ process_instance_id => 1 }) }, qr/name may not be NULL/);

my $pi = $process->new_instance();
my $pia = $rs->create({ process_instance_id => $pi->id, name => 'some var' });
is($rs->count, 1);
isa_ok($pia, 'BPM::Engine::Store::Result::ProcessInstanceAttribute');
$pia->delete();
is($rs->count, 0);

ok($pia->process_instance);
$schema->resultset('ProcessInstance')->create({ process_id => $process->id });
isa_ok($pia->process_instance, 'BPM::Engine::Store::Result::ProcessInstance');


#-- add_to_attributes

$pi = $process->new_instance();

isa_ok(exception { $pi->add_to_attributes() }, 'DBIx::Class::Exception');
like(  exception { $pi->add_to_attributes() }, qr/needs a hash/);
isa_ok(exception { $pi->add_to_attributes({}) }, 'DBIx::Class::Exception');
# mysql: execute failed: Field 'name' doesn't have a default value
#like(  exception { $pi->add_to_attributes({}) }, qr/wfe_process_instance_attr.name may not be NULL/);

ok($pi->add_to_attributes({ name => 'e1',  }));
ok($pi->add_to_attributes({ name => 'e2', value => undef }));
ok($pi->add_to_attributes({ name => 'e3', value => \'NULL' }));
foreach(qw/e1 e2 e3/) {
    ok(!defined $pi->attribute($_)->value);
    }

ok($pi->add_to_attributes({ name => 'e4', value => '' }));
like(exception { $pi->attribute('e4')->value }, qr/malformed JSON string/, 'value, if any, should be a reference');
ok($pi->add_to_attributes({ name => 'e5', value => 'NULL' })); # string
like(exception { $pi->attribute('e5')->value }, qr/malformed JSON string/, 'value, if any, should be a reference');

ok($pi->add_to_attributes({ name => '' }));
isa_ok(exception { $pi->add_to_attributes({ name => ''}) }, 'DBIx::Class::Exception');
# mysql: execute failed: Duplicate entry '3-'
#like(  exception { $pi->add_to_attributes({ name => ''}) }, qr/columns process_instance_id, name are not unique/);

ok( $pi->add_to_attributes({ name => 'number', is_array => 0, value => [55] }), 'number attribute added');
ok( $pi->add_to_attributes({ name => 'string', is_array => 0, value => ['Some Thing'] }), 'string attribute added' );
#ok( $pi->add_to_attributes({ name => 'list',   is_array => 0, value => [55] }), 'list attribute added' );
ok( $pi->add_to_attributes({ name => 'array',  is_array => 1, value => [55], type => 'SchemaType' }), 'array attribute added' );
ok( $pi->add_to_attributes({ name => 'hash',   is_array => 0, value => { some => 'thing' }, type => 'SchemaType' }), 'hash attribute added' );
#ok( $pi->add_to_attributes({ name => 'hashlist',  is_array => 0, value => [{ nr => 55 }], type => 'SchemaType' }), 'hashlist attribute added' );
ok( $pi->add_to_attributes({ name => 'hasharray', is_array => 1, value => [{ nr => 55 }], type => 'SchemaType' }), 'hasharray attribute added' );

#-- attribute

isa_ok(exception { $pi->attribute('counter') }, 'BPM::Engine::Exception::Database', 'simple error thrown' );
like(  exception { $pi->attribute('counter') }, qr/Attribute named 'counter' not found/, 'Invalid attribute okay' );

is($pi->attribute('number')->value, 55);
is($pi->attribute('string')->value, 'Some Thing');
#is_deeply($pi->attribute('list')->value, [55]);
is_deeply($pi->attribute('array')->value, [55]);
is_deeply($pi->attribute('hash')->value, { some => 'thing' });
#is_deeply($pi->attribute('hashlist')->value, [{ nr => 55 }]);
is_deeply($pi->attribute('hasharray')->value, [{ nr => 55 }]);

$pi->attribute('number', 56);
$pi->attribute('string', 'Some Thing Else');
#$pi->attribute('list', [55,56]);
$pi->attribute('hash', { some => 'thing', or => 'else' });
#$pi->attribute('hashlist', [{ nr => 56 }]);
$pi->attribute('hasharray', [{ nr => 56 }]);

is($pi->attribute('number')->value, 56);
is($pi->attribute('string')->value, 'Some Thing Else');
#is_deeply($pi->attribute('list')->value, [55,56]);
is_deeply($pi->attribute('hash')->value, { some => 'thing', or => 'else' });
#is_deeply($pi->attribute('hashlist')->value, [{ nr => 56 }]);
is_deeply($pi->attribute('hasharray')->value, [{ nr => 56 }]);

#-- update

#$attr->update({ value => [55] });
#is($attr->discard_changes->value->[0],'55');
#is($pi->attribute('counter')->value->[0],'55');

#- create_attributes

isa_ok(exception { $pi->create_attributes() }, 'BPM::Engine::Exception::Parameter');
like(  exception { $pi->create_attributes() }, qr/Need scope and data fields/);

my $formal1 = {"Id"=>"counter","Mode"=>"OUT","DataType"=>{"BasicType"=>{"Type"=>"INTEGER"}}};
my $formal2 = {"Id"=>"counter", value => 11 };

isa_ok(exception { $pi->create_attributes('params', [$formal1, $formal2]) }, 'DBIx::Class::Exception');
# mysql: Duplicate entry
#like(  exception { $pi->create_attributes('params', [$formal1, $formal2]) }, qr/process_instance_id, name are not unique/);

like(  exception { $pi->attribute('counter') }, qr/Attribute named 'counter' not found/, 'Invalid attribute okay' );
is(exception { $pi->create_attributes('params', [$formal1]) }, undef);
ok($pi->attribute('counter'));

$pi = $process->new_instance();
# mysql: execute failed: Data truncated for column 'scope'
#ok( !$pi->create_attributes('blah', [{ Id => 'number', IsArray => 0, InitialValue => { content => 55 }, DataType => { BasicType => { Type => 'STRING' } } }]) );
ok( !$pi->create_attributes('fields', [{ Id => 'number', IsArray => 0, InitialValue => { content => 55 }, DataType => { BasicType => { Type => 'STRING' } } }]) );
ok( !$pi->create_attributes(fields => [{ Id => 'string', IsArray => 0, InitialValue => { content => '"Some Thing"' }, DataType => { BasicType => { Type => 'STRING' } } }]) );
ok( !$pi->create_attributes(container => [{ Id => 'array',  IsArray => 1, InitialValue => { content => '[55]' }, DataType => { BasicType => { Type => 'INTEGER' } } }]) );
ok( !$pi->create_attributes(params => [{ Id => 'hash',   IsArray => 0, InitialValue => { content => "{ some => 'thing' }" } }]) );
ok( !$pi->create_attributes(fields => [{ Id => 'hasharray', IsArray => 1, InitialValue => { content => '[{ nr => 55 }]' } }]) );

is($pi->attribute('number')->value, 55);
is($pi->attribute('string')->value, 'Some Thing');
is_deeply($pi->attribute('array')->value, [55]);
is_deeply($pi->attribute('hash')->value, { some => 'thing' });
is_deeply($pi->attribute('hasharray')->value, [{ nr => 55 }]);

done_testing;
