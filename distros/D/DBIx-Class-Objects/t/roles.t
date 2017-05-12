use Test::Most;
use lib 't/lib';
use My::Objects;
use My::Fixtures;
use Sample::Schema;

my $schema = Sample::Schema->test_schema;

my $fixtures = My::Fixtures->new( { schema => $schema } );
$fixtures->load('user');
my $objects = My::Objects->new(
    {   schema      => $schema,
        object_base => 'My::Object::',
        debug       => 0,
	roles       => [qw( My::Role::Thing )]
    }
);
$objects->load_objects;

my $user = $objects->objectset('User')->first;
ok $user, 'there is a user';
ok $user->can('doThing'), 'Can do a thing';
ok $user->doThing eq 'done', 'thing is done';

done_testing;
