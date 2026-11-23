#!/usr/bin/env perl

# State transitions of the login (config password_hash), a machine documented in
# the POD of Database::BI::Controller::Dashboard (login, logout, require_login)
# and in CLAUDE.md, not by a diagram of its own.  The states are seen from outside:
#
#   ANONYMOUS  -- no session; a protected route answers 401.
#   COUNTING   -- ANONYMOUS with 1 to ATTEMPTS-1 wrong passwords inside the window.
#   LOCKED     -- ATTEMPTS wrong passwords inside the window; /login answers 429.
#   LOGGED_IN  -- the session holds the mark; a protected route answers 200.
#   EXPIRED    -- LOGGED_IN left idle past login_expiration; as ANONYMOUS.
#
#   ANONYMOUS --wrong--> COUNTING --wrong x (ATTEMPTS-1 more)--> LOCKED
#   ANONYMOUS|COUNTING --right--> LOGGED_IN (the count is cleared)
#   LOCKED --right--> LOCKED (the password is not even tried)
#   LOCKED --WINDOW passes--> ANONYMOUS
#   COUNTING --WINDOW passes--> ANONYMOUS (old failures are forgotten)
#   LOGGED_IN --logout--> ANONYMOUS
#   LOGGED_IN --idle past login_expiration--> EXPIRED
#
# Time is Test::Mockingbird::TimeTravel's, reached through CORE::GLOBAL::time, which
# has to exist before the application is compiled.  Nothing sleeps.
#
#   prove -l t/transition-login.t

use strict;
use warnings;

BEGIN {
	require Test::Mockingbird::TimeTravel;
	no warnings 'once';
	*CORE::GLOBAL::time = sub () { Test::Mockingbird::TimeTravel::now() };
}

use File::Temp qw(tempdir);
use Readonly;
use Test::Mockingbird::TimeTravel qw(freeze_time advance_time);
use Test::Mojo;
use Test::Most;

use Database::BI::Password qw(hash_password);

Readonly my %CONFIG => (
	password    => 'correct horse',
	rounds      => 10_000,		# the minimum, to keep the test fast
	attempts    => 10,		# Dashboard's $LOGIN_ATTEMPTS
	window      => 15 * 60,		# its $LOGIN_WINDOW
	expiration  => 600,		# login_expiration used here
	start       => '2030-01-01T00:00:00Z',
	protected   => '/api/analyses',
	wrong       => 'wrong horse',
);
Readonly my $HASH => hash_password($CONFIG{password}, rounds => $CONFIG{rounds});

freeze_time($CONFIG{start});

sub new_app {
	return Test::Mojo->new('Database::BI', {
		model_dir        => tempdir(CLEANUP => 1),
		export_dirs      => [ tempdir(CLEANUP => 1) ],
		password_hash    => $HASH,
		login_expiration => $CONFIG{expiration},
	});
}

sub attempt { my ($t, $password) = @_; return $t->post_ok('/login' => form => { password => $password }) }
sub fail_n  { my ($t, $n) = @_; attempt($t, $CONFIG{wrong})->status_is(401) for 1 .. $n; return }

subtest 'State: ANONYMOUS -> Trigger: protected request -> State: ANONYMOUS (refused)' => sub {
	my $t = new_app();
	$t->get_ok($CONFIG{protected})->status_is(401);
};

subtest 'State: ANONYMOUS -> Trigger: right password -> State: LOGGED_IN' => sub {
	my $t = new_app();
	attempt($t, $CONFIG{password})->status_is(302);
	$t->get_ok($CONFIG{protected})->status_is(200);
};

subtest 'State: ANONYMOUS -> Trigger: wrong password -> State: COUNTING (still refused)' => sub {
	my $t = new_app();
	fail_n($t, 1);
	$t->get_ok($CONFIG{protected})->status_is(401);
};

subtest 'State: COUNTING -> Trigger: ATTEMPTS-1 more wrong passwords -> State: LOCKED' => sub {
	my $t = new_app();
	fail_n($t, $CONFIG{attempts});
	attempt($t, $CONFIG{wrong})->status_is(429);
};

subtest 'State: COUNTING -> Trigger: right password -> State: LOGGED_IN, and the count is cleared' => sub {
	my $t = new_app();
	fail_n($t, $CONFIG{attempts} - 1);
	attempt($t, $CONFIG{password})->status_is(302);
	$t->post_ok('/logout')->status_is(302);
	# A cleared count means a full allowance again: ATTEMPTS wrong, not one.
	fail_n($t, $CONFIG{attempts} - 1);
	attempt($t, $CONFIG{wrong})->status_is(401);
};

subtest 'State: LOCKED -> Trigger: right password -> State: LOCKED (illegal transition, refused)' => sub {
	my $t = new_app();
	fail_n($t, $CONFIG{attempts});
	attempt($t, $CONFIG{password})->status_is(429);
	$t->get_ok($CONFIG{protected})->status_is(401);
	like $t->tx->res->json->{error}, qr/Log in first/, 'and nothing was granted';
};

subtest 'State: LOCKED -> Trigger: WINDOW elapses -> State: ANONYMOUS, then LOGGED_IN' => sub {
	my $t = new_app();
	fail_n($t, $CONFIG{attempts});
	advance_time($CONFIG{window} - 1);
	attempt($t, $CONFIG{password})->status_is(429);
	advance_time(2);
	attempt($t, $CONFIG{password})->status_is(302);
	$t->get_ok($CONFIG{protected})->status_is(200);
};

subtest 'State: COUNTING -> Trigger: WINDOW elapses -> State: ANONYMOUS (old failures forgotten)' => sub {
	my $t = new_app();
	fail_n($t, $CONFIG{attempts} - 1);
	advance_time($CONFIG{window} + 1);
	fail_n($t, $CONFIG{attempts} - 1);	# would be locked if the first nine still counted
	attempt($t, $CONFIG{password})->status_is(302);
};

subtest 'State: LOCKED is per client application: another app is not locked' => sub {
	my $locked = new_app();
	fail_n($locked, $CONFIG{attempts});
	my $other = new_app();
	attempt($other, $CONFIG{password})->status_is(302);
};

subtest 'State: LOGGED_IN -> Trigger: logout -> State: ANONYMOUS' => sub {
	my $t = new_app();
	attempt($t, $CONFIG{password})->status_is(302);
	$t->post_ok('/logout')->status_is(302)->header_is(Location => '/login');
	$t->get_ok($CONFIG{protected})->status_is(401);
	$t->post_ok('/logout')->status_is(302);	# logging out when out is not an error
};

subtest 'State: LOGGED_IN -> Trigger: idle for less than login_expiration -> State: LOGGED_IN (and the clock restarts)' => sub {
	my $t = new_app();
	attempt($t, $CONFIG{password})->status_is(302);
	for (1 .. 3) {
		advance_time($CONFIG{expiration} - 1);
		$t->get_ok($CONFIG{protected})->status_is(200);
	}
};

subtest 'State: LOGGED_IN -> Trigger: idle past login_expiration -> State: EXPIRED' => sub {
	my $t = new_app();
	attempt($t, $CONFIG{password})->status_is(302);
	advance_time($CONFIG{expiration} + 1);
	$t->get_ok($CONFIG{protected})->status_is(401);
	attempt($t, $CONFIG{password})->status_is(302);	# EXPIRED -> LOGGED_IN by logging in again
	$t->get_ok($CONFIG{protected})->status_is(200);
};

subtest 'State: LOGGED_IN -> Trigger: the password hash changes -> State: ANONYMOUS' => sub {
	my $t = new_app();
	attempt($t, $CONFIG{password})->status_is(302);
	$t->app->config->{password_hash} = hash_password('another', rounds => $CONFIG{rounds});
	$t->get_ok($CONFIG{protected})->status_is(401);
};

done_testing();
