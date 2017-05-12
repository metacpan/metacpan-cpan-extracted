
use strict;
use Test::More 'no_plan';
use lib 't';
use CGI;
use URI;

{
    package MyTestApp;

    use base 'TestApp';
    use TestCDBI;

    sub setup {
        my $self = shift;
        $self->run_modes([ qw(main_display page_the_second page_the_third) ]);
        $self->SUPER::setup();
    }

    sub _relogin_test {
        return 1;
    }
    sub page_the_second {
        my $self = shift;
        $self->stash->{'Seen_Run_Mode'}{'page_the_second'} = 1;
        $self->stash->{'Final_Run_Mode'}                   = 'page_the_second';
        '';
    }
    sub page_the_third {
        my $self = shift;
        $self->stash->{'Seen_Run_Mode'}{'page_the_third'} = 1;
        $self->stash->{'Final_Run_Mode'}                   = 'page_the_third';
        '';
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
        my ($user) = TestCDBI::users->search(
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
# Fake that we've come from the login page with good parameters
$app   = MyTestApp->new(QUERY => $query);
$query->param('username',     'test');
$query->param('password',     'seekrit');
$app->run;

ok($app->stash->{'User_OK'},                          '[login, good parms] valid user');
ok($app->stash->{'Password_OK'},                      '[login, good parms] valid password');

my $session_id;
if ($app->stash->{'Cookie'} =~ m{^\s*session_id=(\S*);\s+path=/\s*$}i ) {
    $session_id = $1;
}

like($session_id, qr/^[a-fA-F0-9]+$/, '[login, good parms] Session looks valid');

is($app->session->{username}, 'test', '[login, good parms] user is test');
is($app->session->{wubba},    'yes',  '[login, good parms] session value wubba');

$app->session->{'tambourine'} = 'green';
is($app->session->{'tambourine'},    'green',  '[login, good parms] stored session value tambourine');

ok($app->stash->{'Seen_Run_Mode'}{'main_display'},  '[login, good parms] fall through to main_display');
is($app->stash->{'Final_Run_Mode'}, 'main_display', '[login, good parms] final page was main_display');

my $link = $app->make_link(
    qs_args => {
        rm => 'page_the_second',
    }
);

my $uri = URI->new($link);
my %link_params = $uri->query_form;

$query                       = new CGI;
$query->param('rm',          $link_params{'rm'}          );
$query->param('_session_id', $link_params{'_session_id'} );
$query->param('_checksum',   $link_params{'_checksum'}   );

$app   = MyTestApp->new(QUERY => $query);
$app->run;


ok($app->stash->{'Seen_Run_Mode'}{'page_the_second'},  '[page_the_second] fall through to page_the_second');
is($app->stash->{'Final_Run_Mode'}, 'page_the_second', '[page_the_second] final page was page_the_second');

my $new_session_id = $app->get_session_id;

is($new_session_id, $session_id, '[page_the_second] session_id is the same between apps');

is($app->session->{username},     'test',   '[page_the_second] user is test');
is($app->session->{wubba},        'yes',    '[page_the_second] session value wubba');
is($app->session->{'tambourine'}, 'green',  '[page_the_second] session value tambourine');

$app->session->{'tambourine'} = 'tangerine';
is($app->session->{'tambourine'},    'tangerine',  '[login, good parms] stored session value tangerine');


$link = $app->make_link(
    qs_args => {
        rm => 'page_the_third',
    }
);

$uri = URI->new($link);
%link_params = $uri->query_form;

$query                       = new CGI;
$query->param('rm',          $link_params{'rm'}          );
$query->param('_session_id', $link_params{'_session_id'} );
$query->param('_checksum',   $link_params{'_checksum'}   );

$app   = MyTestApp->new(QUERY => $query);
$app->run;


ok($app->stash->{'Seen_Run_Mode'}{'page_the_third'},  '[page_the_third] fall through to page_the_third');
is($app->stash->{'Final_Run_Mode'}, 'page_the_third', '[page_the_third] final page was page_the_third');

$new_session_id = $app->get_session_id;

is($new_session_id, $session_id, '[page_the_third] session_id is the same between apps');

is($app->session->{username},     'test',      '[page_the_third] user is test');
is($app->session->{wubba},        'yes',       '[page_the_third] session value wubba');
is($app->session->{'tambourine'}, 'tangerine', '[page_the_third] session value tambourine');



