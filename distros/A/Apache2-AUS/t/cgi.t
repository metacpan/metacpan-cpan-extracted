#!/usr/bin/perl

use strict;
use warnings;
use lib "t/tlib";
use t::dbh;
use Apache::Test qw(:withtestmore);
use Apache::TestRequest qw(GET_BODY POST_BODY GET);
use Apache::TestUtil;
use DBIx::Migration::Directories::Test;
use DBIx::Transaction;
use Test::More qw(no_plan);
use Schema::RDBMS::AUS::User;

my(@db_opts) = test_db()
    or plan skip_all => 'Schema DSN was not set';

my $config   = Apache::Test::config();
my $hostport = Apache::TestRequest::hostport($config) || '';
my $dbh = DBIx::Transaction->connect(@db_opts)
    or die "Failed to connect to database";

my $path = "/test/apache2-aus-cgi";

my @go = (go => "$path/env.cgi", go_error => "$path/login.cgi");

my $self = {dbh => $dbh};

t_debug("connecting to $hostport");
my $test = "Got a session id";
my $received;
$received = GET_BODY "$path/env.cgi";
if($received =~ m{AUS_SESSION_ID\' \=\> \'(.+?)\'}) {
    $self->{_session} = $1;
    pass($test);
} else {
    fail($test);
}

Apache::TestRequest::user_agent(reset=> 1, cookie_jar => {});
$received = GET_BODY "$path/env.cgi";
unlike(
    $received, qr{AUS_SESSION_ID\' \=\> \'\Q$self->{_session}\E\'},
    "Session ID on second request doesn't match without a cookie"
);
$self->{_received} = $received;

$received = delete $self->{_received};
delete $self->{_session};
$test = "Got a new session id";
if($received =~ m{AUS_SESSION_ID\' \=\> \'(.+?)\'}) {
    $self->{_session} = $1;
    pass($test);
} else {
    fail($test);
}

$received = GET_BODY "$path/env.cgi";
$self->{_received} = $received;
like(
    $received, qr{AUS_SESSION_ID\' \=\> \'\Q$self->{_session}\E\'},
    "Session ID on second request matches with a cookie"
);

unlike(
    $self->{_received}, qr{REMOTE_USER},
    "We don't have a REMOTE_USER yet"
);
delete $self->{_received};

$received = GET_BODY "$path/login.cgi";
like($received, qr{<B></B>}, "Got login page, no message.");

$received = POST_BODY(
    "$path/login",
    [ user => "kristina", password => "tampon", @go ]
);
like(
    $received,
    qr{\Q<B>User not found.\E}, "Get correct error for bad user"
);

my $user = Schema::RDBMS::AUS::User->create(
    _dbh        => $self->{dbh},
    name        => "kristina",
    _password   => "rum"
);
ok($user->save, "Created a user");
$self->{_user} = $user;

$received = POST_BODY(
    "$path/login", [ user => "kristina", password => "tampon", @go ]
);
like(
    $received,
    qr{\Q<B>Bad password for user\E},
    "Got bad password error"
);

$received = GET_BODY("$path/protected.cgi");
unlike($received, qr{You made it}, "Can't hit protected page without login");

$received = POST_BODY(
    "$path/login", [ user => "kristina", password => "rum", @go ]
);
$test = "REMOTE_USER set on successful login";
if($received =~ m{REMOTE_USER'?\s+=>\s+'?(\d+)'?}) {
    $self->{_user_id} = $1;
    pass($test);
} else {
    diag($received);
    fail($test);
}

is(
    $self->{_user_id}, $self->{_user}->{id},
    "REMOTE_USER variable matches our user id"
);
delete($self->{_user_id});

$received = GET_BODY "$path/login.cgi";
like(
    $received,
    qr{<B>Logged in as kristina},
    "Login page shows that we are already logged in"
);

$received = GET_BODY("$path/protected.cgi");
like($received, qr{You made it}, "Can hit protected page with login");

$received = GET_BODY("$path/admin.cgi");
unlike($received, qr{Admin test}, "Can't hit admin-protected page");

ok($self->{_user}->set_flag("administrator"), "Set admin flag");

ok($self->{_user}->flag("administrator"), "Flag set before save");

ok(
    !$self->{_user}->permission("administrator"),
    "Permission not set before save"
);

ok($self->{_user}->save, "Save user");

ok(
    $self->{_user}->permission("administrator"),
    "Permission set after save"
);

$user = Schema::RDBMS::AUS::User->load(
    name => "kristina", _dbh => $self->{dbh}
);
$self->{__user} = $user;
ok($user->flag("administrator"), "User has admin flag");

ok($self->{__user}->permission("administrator"), "User has admin permission");
delete $self->{__user};

$received = GET_BODY("$path/admin.cgi");
like($received, qr{Admin test}, "Can hit admin-protected page with admin set");

$received = GET_BODY("$path/session.cgi");
unlike($received, qr{barwhore}, "Session value is not set yet");

GET("$path/set.cgi?set=barwhore");
$received = GET_BODY("$path/session.cgi");
like($received, qr{barwhore}, "Session value is set after calling set.cgi");
