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
    }
);
$objects->load_objects;

my $user = $objects->objectset('User')->first;
my $session = $objects->objectset('Session')->first;

my $uid = $user->username;
$session->username($uid);
$session->update();
is $session->username, $user->username, "storing in a nullable relation works";

my $db_session = $schema->resultset('Session')->first;
is $db_session->username, $user->username, "...and that's actually in the db now";

# assuming tests above went wrong, force it:
$db_session->username($uid);
$db_session->update();

$session = $objects->objectset('Session')->first; # why must moose obj be reloaded?

is ref($session->user), "My::Object::User", "username refers to the right class now";
is ref($db_session->user), "Sample::Schema::Result::User", "...ditto for dbic";

$session->username(undef);
$session->update();

is $session->username, undef, "nulling the relation works";

done_testing;
