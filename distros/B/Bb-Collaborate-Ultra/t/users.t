use warnings; use strict;
use Test::More tests => 9;
use Test::Fatal;
use Date::Parse;
use lib '.';
use t::Ultra;

 SKIP: {
     my %t = t::Ultra->test_connection;
     my $connection = $t{connection};
     skip $t{skip} || 'skipping live tests', 9
	 unless $connection;

     $connection->connect;

     use Bb::Collaborate::Ultra::User;
     my $user;
     is exception {
	 $user = Bb::Collaborate::Ultra::User->post($connection, {
	     displayName => 'Test User',
	     firstName => 'Test',
	     lastName => 'User',
	     extId => 'test-user',
	     email => 'test-user@example.org',
						    },
	     );
     }, undef, "user post - lives";

     is $user->displayName, 'Test User', 'user name';
     $user->displayName('Test User - Updated');

     my @changed = $user->changed;
     is_deeply \@changed, ['displayName'], 'changed fields';
     my $updates = $user->_pending_updates;
     is_deeply $updates, { 'id' => $user->id, displayName => 'Test User - Updated', }, 'updateable data';
     is exception { $user->patch }, undef, 'patch updates - lives';
     $updates = $user->_pending_updates;
     delete $updates->{active}; # ignore this
     is_deeply $updates, { 'id' => $user->id, }, 'updates are flushed';
     my @users = Bb::Collaborate::Ultra::User->get($connection, { id => $user->id});
						   is scalar @users, 1, 'get test user';

						   is $users[0]->displayName, 'Test User - Updated', 'get test suser';
						   is exception { $user->delete }, undef, 'user delete lives';

}
