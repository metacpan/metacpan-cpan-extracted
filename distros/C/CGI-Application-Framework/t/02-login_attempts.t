
use strict;
use Test::More 'no_plan';
use CGI;
use lib 't';

{
    package MyTestApp;

    use base 'TestApp';
    use TestCDBI;

    sub setup {
        my $self = shift;
        $self->run_modes([ qw(main_display) ]);
        $self->SUPER::setup();
    }

}

#######################################################################
# Subclass with a custom _login_profile requiring the username to be an
# email address and the password to be a binary number

{
    package MyTestApp_custom_login_profile;

    use base 'MyTestApp';
    sub _login_profile {
        return {
            required     => [ qw ( username password ) ],
            constraints  => {
                username => 'email',
                password => qr/^[10]+$/,
            },
            msgs     => {
                any_errors => 'some_errors', # just want to set a true value here
                prefix     => 'err_',
            },
        };
    }

}

#######################################################################
# Subclass with a custom _login_authenticate that ignores the username
# and password and always returns the user 'bubba'
{
    package MyTestApp_custom_login_authenticate;

    use base 'MyTestApp';

    # This strange _login_authenticate sub always returns the user 'bubba'
    sub _login_authenticate {
        my $self = shift;
        my ($user) = TestCDBI::Users->search(
            username => 'bubba',
        );

        if ($user) {
            $self->stash->{'User_OK'}     = 1;
            $self->stash->{'Password_OK'} = 1;
        }

        return (1, $user);
    }

}


# Set up query and app
my ($query, $app);
$query = new CGI;
$query->param('come_from_rm', 'login');
$query->param('current_rm',   'login');
$query->param('rm',           'main_display');


#######################################################################
# Fake that we've come from the login page with bad form parameters
# (missing username and password)
$app   = MyTestApp->new(QUERY => $query);
is(ref $app, 'MyTestApp', 'MyTestApp loaded okay');
$query->param('username',     '');
$query->param('password',     '');

$app->run;
ok($app->stash->{'Seen_Run_Mode'}{'login'},       '[login, bad parms (missing username and password)] redirected to login');
ok($app->stash->{'Seen_Run_Mode'}{'_echo_page'},  '[login, bad parms (missing username and password)] redirected via echo page');
is($app->stash->{'Final_Run_Mode'}, '_echo_page', '[login, bad parms (missing username and password)] final page was echo page');

#######################################################################
# Fake that we've come from the login page with bad form parameters
# (missing username)
$app   = MyTestApp->new(QUERY => $query);
$query->param('username',     '');
$query->param('password',     'seekrit');

$app->run;
ok($app->stash->{'Seen_Run_Mode'}{'login'},       '[login, bad parms (missing username)] redirected to login');
ok($app->stash->{'Seen_Run_Mode'}{'_echo_page'},  '[login, bad parms (missing username)] redirected via echo page');
is($app->stash->{'Final_Run_Mode'}, '_echo_page', '[login, bad parms (missing username)] final page was echo page');


#######################################################################
# Fake that we've come from the login page with arbitrary form parameters
# with custom _login_authenticate
$app   = MyTestApp_custom_login_authenticate->new(QUERY => $query);
is(ref $app, 'MyTestApp_custom_login_authenticate', 'MyTestApp_custom_login_authenticate loaded okay');
$query->param('username',     'foo');
$query->param('password',     'bar');


$app->run;

ok($app->stash->{'User_OK'},                          '[login, custom _login_authenticate] valid user');
ok($app->stash->{'Password_OK'},                      '[login, custom _login_authenticate] valid password');

my $session_id;
if ($app->stash->{'Cookie'} =~ m{^\s*session_id=(\S*);\s+path=/\s*$}i ) {
    $session_id = $1;
}

like($session_id, qr/^[a-fA-F0-9]+$/,               '[login, custom _login_authenticate] Session looks valid');
is($app->session->{username}, 'bubba',              '[login, custom _login_authenticate] user is always bubba');
is($app->session->{fullname}, 'Bubba the Beatific', '[login, custom _login_authenticate] user is always beatific');


#######################################################################
# Fake that we've come from the login page with bad form parameters
# with custom profile
$app   = MyTestApp_custom_login_profile->new(QUERY => $query);
is(ref $app, 'MyTestApp_custom_login_profile', 'MyTestApp_custom_login_profile loaded okay');
$query->param('username',     'test');
$query->param('password',     'seekrit');

$app->run;
ok($app->stash->{'Seen_Run_Mode'}{'login'},       '[login, bad parms (custom profile)] redirected to login');
ok($app->stash->{'Seen_Run_Mode'}{'_echo_page'},  '[login, bad parms (custom profile)] redirected via echo page');
is($app->stash->{'Final_Run_Mode'}, '_echo_page', '[login, bad parms (custom profile)] final page was echo page');


#######################################################################
# Fake that we've come from the login page with bad form parameters
# with custom profile
$app   = MyTestApp_custom_login_profile->new(QUERY => $query);
$query->param('username',     'test@example.com');
$query->param('password',     'seekrit');

$app->run;
ok($app->stash->{'Seen_Run_Mode'}{'login'},       '[login, bad parms (custom profile - password not binary)] redirected to login');
ok($app->stash->{'Seen_Run_Mode'}{'_echo_page'},  '[login, bad parms (custom profile - password not binary)] redirected via echo page');
is($app->stash->{'Final_Run_Mode'}, '_echo_page', '[login, bad parms (custom profile - password not binary)] final page was echo page');



#######################################################################
# Fake that we've come from the login page with bad form parameters
# with custom profile
$app   = MyTestApp_custom_login_profile->new(QUERY => $query);
$query->param('username',     'test@example.com');
$query->param('password',     '1001001');

$app->stash->{'Suppress_Output'} = 1;
$app->run;
ok($app->stash->{'User_OK'},                          '[login, good parms] valid user');
ok(!$app->stash->{'Password_OK'},                     '[login, good parms] but invalid password');
undef $app->stash->{'Suppress_Output'};

ok($app->stash->{'Seen_Run_Mode'}{'login'},  '[login, good parms (custom profile) but user does not exist] redirected to login');
is($app->stash->{'Final_Run_Mode'}, 'login', '[login, good parms (custom profile) but user does not exist] final page was login');


#######################################################################
# Fake that we've come from the login page with good parameters
$app   = MyTestApp->new(QUERY => $query);
$query->param('username',     'test');
$query->param('password',     'seekrit');
$app->run;

ok($app->stash->{'User_OK'},                          '[login, good parms] valid user');
ok($app->stash->{'Password_OK'},                      '[login, good parms] valid password');

undef $session_id;
if ($app->stash->{'Cookie'} =~ m{^\s*session_id=(\S*);\s+path=/\s*$}i ) {
    $session_id = $1;
}

like($session_id, qr/^[a-fA-F0-9]+$/, '[login, good parms] Session looks valid');

is($app->session->{username}, 'test', '[login, good parms] user is test');
is($app->session->{wubba},    'yes',  '[login, good parms] stored session value');

ok($app->stash->{'Seen_Run_Mode'}{'main_display'},  '[login, good parms] fall through to main_display');
is($app->stash->{'Final_Run_Mode'}, 'main_display', '[login, good parms] final page was main_display');




