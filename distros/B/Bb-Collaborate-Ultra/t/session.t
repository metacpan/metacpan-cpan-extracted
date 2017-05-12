use warnings; use strict;
use Test::More tests => 21;
use Test::Fatal;
use Date::Parse;
use lib '.';
use t::Ultra;

SKIP: {
    my %t = t::Ultra->test_connection;
    my $connection = $t{connection};
    skip $t{skip} || 'skipping live tests', 21
	unless $connection;

    $connection->connect;

    my $start = time() + 60;
    my $end = $start + 900;

    use Bb::Collaborate::Ultra::Session;
    my $session;
    is exception {
	$session = Bb::Collaborate::Ultra::Session->post($connection, {
	    name => 'Test Session',
	    startTime => $start,
	    endTime   => $end,
	    },
	);
    }, undef, "session post - lives";

    is $session->name, 'Test Session', 'session name';
    is $session->startTime, $start, 'session start';
    is $session->endTime, $end, 'session end';

    $session->name('Test Session - Updated');
    $session->endTime( $session->endTime + 60);

    my @changed = $session->changed;
    is_deeply \@changed, ['endTime', 'name'], 'changed fields';
    my $updates = $session->_pending_updates;
    is_deeply $updates, { 'id' => $session->id, name => 'Test Session - Updated', endTime => $session->endTime, }, 'updateable data';
    is exception { $session->patch }, undef, 'patch updates - lives';
    $updates = $session->_pending_updates;
    delete $updates->{active}; # ignore this
    is_deeply $updates, { 'id' => $session->id, }, 'updates are flushed';
    my @enrollments = $session->get_enrollments;
    is scalar @enrollments, 0, 'no session enrolments yet';

    require Bb::Collaborate::Ultra::User;
    my $launch_user = Bb::Collaborate::Ultra::User->new({
	extId => 'testLaunchUser',
	displayName => 'David Warring',
	email => 'david.warring@gmail.com',
	firstName => 'David',
	lastName => 'Warring',
    });

    require Bb::Collaborate::Ultra::LaunchContext;
    my $launch_context =  Bb::Collaborate::Ultra::LaunchContext->new({ launchingRole => 'moderator',
	 editingPermission => 'writer',
	 user => $launch_user,
	 });

    my $url;
    is exception {
	$url = $launch_context->join_session($session);
    }, undef, 'launch context join session - lives';

    ok $url, "got launch_context url";

    my $user = Bb::Collaborate::Ultra::User->post($connection, {
	extId => 'testEnrolUser',
	displayName => 'David Warring',
	email => 'david.warring@gmail.com',
	firstName => 'David',
	lastName => 'Warring',
    });
    require Bb::Collaborate::Ultra::Session::Enrollment;
    my $enrollment =  Bb::Collaborate::Ultra::Session::Enrollment->new({ launchingRole => 'moderator',
	 editingPermission => 'writer',
	 userId => $user->id,
	 });

    is exception {
	$enrollment = $enrollment->enrol($session);
    }, undef, '$enrol session - lives';

    ok $enrollment, "got launch_context url";

    @enrollments = $session->get_enrollments;
    is scalar @enrollments, 2, 'both users are now enrolled';
    $enrollment = $enrollments[0];

    is $enrollment->editingPermission, 'writer', 'enrolment editingPermission';

    my @sessions = Bb::Collaborate::Ultra::Session->get($connection, {
	limit => 5,
    });

    ok scalar @sessions <= 5 && scalar @sessions > 0, 'get sessions - with limits';

    my $context;
    my $session_id = $session->id;
    is exception {
	require Bb::Collaborate::Ultra::Context;
	$context = Bb::Collaborate::Ultra::Context->find_or_create(
	    $connection, {
		extId => 'session.t',
		name => 'sesson.t - test context',
		label => 'session.t',
	    });

	$context->associate_session($session);
    }, undef, '$context->associate_session(...) - lives';

    is exception {
	@sessions = Bb::Collaborate::Ultra::Session->get($connection, {contextId => $context->id, limit => 5}, )
    }, undef, 'fetch session by context - lives';
    ok scalar(@sessions), 'fetch session by context - results';

    is exception { $session->delete }, undef, 'session->delete - lives';
    is exception { $user->delete }, undef, 'user->delete - lives';
}
