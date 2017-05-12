use warnings; use strict;
use Test::More tests => 35;
use Test::Fatal;
use JSON;
# ----------------------------------------------------------------
use Bb::Collaborate::Ultra::Session;

ok(Bb::Collaborate::Ultra::Session->can('startTime'), "accessor introspection");

my $types = Bb::Collaborate::Ultra::Session->_property_types;

ok exists $types->{startTime}, "property_types introspection"
    or diag explain {'session.types' => $types};

my $now = time;
my $session_json = '{"id":"abc123456","name":"Test Session","startTime":"2016-12-20T01:44:54.000Z","endTime":"2016-12-20T02:00:54.000Z","boundaryTime":15,"allowGuest":true,"telephonyEnabled":false,"occurrences": [ { "id":"xyz248","startTime":"2016-12-20T01:44:54.000Z","endTime":"2016-12-20T02:00:54.000Z", "active" : true } ] }';
my $session_data = Bb::Collaborate::Ultra::Session->_thaw( from_json($session_json) );

my %session_data = %$session_data;
do {
   delete $session_data{startTime};
   isnt exception { Bb::Collaborate::Ultra::Session->new(\%session_data)}, undef, 'create session without required - dies';
};

%session_data = %$session_data;
my $session;
 is exception { $session = Bb::Collaborate::Ultra::Session->new($session_data)}, undef, 'create session with required - lives';

isa_ok $session, 'Bb::Collaborate::Ultra::Session', 'session';
is $session->id, 'abc123456', 'session->id';
is $session->allowGuest, 1, 'Bool (true)';
is $session->telephonyEnabled, 0, 'Bool (false)';
is $session->startTime, 1482198294, 'Date';;
is $session->occurrences->[0]->startTime, 1482198294, 'session occurrences dereference';

my $frozen;
my $thawed;
is exception { $frozen = from_json($session->_freeze) }, undef, '$session->_freeze - lives';
is exception { $thawed = $session->_thaw($frozen) }, undef, '$session->_thaw - lives';
is_deeply $thawed, \%session_data, '$session data freeze/thaw round-trip';
is exception { Bb::Collaborate::Ultra::Session->new($thawed) }, undef, '$session recreate from roundtrip data';

isnt exception { $session->guestRole('lacky') }, undef, 'enum - invalid';
isnt  $session->guestRole, 'lacky', 'enum - invalid';

is exception { $session->guestRole('participant') }, undef, 'enum - valid';
is  $session->guestRole, 'participant', 'enum - valid';

isa_ok $session->occurrences, 'ARRAY', 'sub-object coercement';
isa_ok $session->occurrences->[0], 'Bb::Collaborate::Ultra::Session::Occurrence', 'sub-object coercement';
is $session->occurrences->[0]->id, 'xyz248', 'sub-object coercement';

# ----------------------------------------------------------------
use Bb::Collaborate::Ultra::User;

my %user_data = (
    'id' => 'xyz345',
    'userName' => 'Alice'
    );

my $user;
is exception { $user = Bb::Collaborate::Ultra::User->new(\%user_data)}, undef, 'create user - lives';

isa_ok $user, 'Bb::Collaborate::Ultra::User', 'user';
is $user->id, 'xyz345', 'user->id';
is $user->userName, 'Alice', 'user->userName';
is exception { $thawed = from_json $user->_freeze, }, undef, 'user freeze/thaw round trip - lives';
is_deeply $thawed, \%user_data, 'user freeze/thaw round trip - data';

# ----------------------------------------------------------------
use Bb::Collaborate::Ultra::LaunchContext;

my %launch_context_data = (
    'launchingRole' => 'participant',
    'user' => {
	'id' => 'xyz248',
	'userName' => 'Bob'
    },
    );

my $launch_context;
is exception { $launch_context = Bb::Collaborate::Ultra::LaunchContext->new(\%launch_context_data)}, undef, 'create launch_context - lives';

isa_ok $launch_context, 'Bb::Collaborate::Ultra::LaunchContext', 'launch_context';
is $launch_context->launchingRole, 'participant', 'launch_context->launchingRole';

$user = $launch_context->user;

isa_ok $user, 'Bb::Collaborate::Ultra::User', 'launch_context->user';
is $user->id, 'xyz248', 'launch_context->user->id';
is $user->userName, 'Bob', 'launch_context->user->userName';

is exception { $thawed = from_json $launch_context->_freeze }, undef, 'launch context freeze/thaw round-trip - lives';
is_deeply $thawed, \%launch_context_data, 'launch context freeze/thaw round trip - data';

# ----------------------------------------------------------------
done_testing;
