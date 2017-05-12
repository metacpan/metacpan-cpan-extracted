
use strict;
# use Test::More 'no_plan';
use Test::More 'tests' => 42;
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
    sub invalid_checksum {
        my $self = shift;
        $self->stash->{'Seen_Run_Mode'}{'invalid_checksum'} = 1;
        $self->stash->{'Final_Run_Mode'}                    = 'invalid_checksum';
        '';
    }
}

# Set up query and app


#######################################################################
# Fake that we've come from the login page with good parameters

my ($query, $app, $link, $session_id);
sub setup_app {
    $query = new CGI;
    $query->param('come_from_rm', 'login');
    $query->param('current_rm',   'login');
    $query->param('rm',           'main_display');
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
            rm     => 'page_the_second',
            cereal => 'oatmeal',
        }
    );

    return ($app, $query, $link, $session_id);
}


#######################################################################
# Make link works

($app, $query, $link, $session_id) = setup_app();

my $uri   = URI->new($link);
my %param = $uri->query_form;
$ENV{'QUERY_STRING'}  = $uri->query;
$query    = new CGI;

$query->param($_, $param{$_}) for keys %param;

$app   = MyTestApp->new(QUERY => $query);
$app->run;

ok($app->stash->{'Seen_Run_Mode'}{'page_the_second'},  '[link] fall through to page_the_second');
is($app->stash->{'Final_Run_Mode'}, 'page_the_second', '[link] final page was page_the_second');

my $new_session_id = $app->get_session_id;

is($new_session_id, $session_id, '[link] session_id is the same between apps');

is($app->session->{username},     'test',   '[link] user is test');
is($app->session->{wubba},        'yes',    '[link] session value wubba');
is($app->session->{'tambourine'}, 'green',  '[link] session value tambourine');



#######################################################################
# Make link fails on tampered param: cereal
($app, $query, $link, $session_id) = setup_app();

$uri   = URI->new($link);
%param = $uri->query_form;
$query    = new CGI;

$query->param($_, $param{$_}) for keys %param;


$ENV{'QUERY_STRING'} =~ s/cereal=([^&]+)/cereal=wheaties/;

$app   = MyTestApp->new(QUERY => $query);
$app->run;

ok($app->stash->{'Seen_Run_Mode'}{'invalid_checksum'},  '[link - tampered: changed param cereal] fall through to invalid_checksum');
is($app->stash->{'Final_Run_Mode'}, 'invalid_checksum', '[link - tampered: changed param cereal] final page was invalid_checksum');

$new_session_id = $app->get_session_id;

like($session_id, qr/^[a-fA-F0-9]+$/, '[link - tampered: changed param cereal] Session looks valid');

ok(!$app->session->{username},     '[link - tampered: changed param cereal] no username');
ok(!$app->session->{wubba},        '[link - tampered: changed param cereal] no session value wubba');
ok(!$app->session->{'tambourine'}, '[link - tampered: changed param cereal] no session value tambourine');


#######################################################################
# Make link fails on tampered param: rm
($app, $query, $link, $session_id) = setup_app();
$ENV{'QUERY_STRING'} = 1;

$uri   = URI->new($link);
%param = $uri->query_form;
$query    = new CGI;

$query->param($_, $param{$_}) for keys %param;

$ENV{'QUERY_STRING'} =~ s/cereal=([^&]+)/rm=page_the_third/;

$app   = MyTestApp->new(QUERY => $query);
$app->run;

ok($app->stash->{'Seen_Run_Mode'}{'invalid_checksum'},  '[link - tampered: changed param rm] fall through to invalid_checksum');
is($app->stash->{'Final_Run_Mode'}, 'invalid_checksum', '[link - tampered: changed param rm] final page was invalid_checksum');

$new_session_id = $app->get_session_id;

like($session_id, qr/^[a-fA-F0-9]+$/, '[link - tampered: changed param rm] Session looks valid');

ok(!$app->session->{'username'},   '[link - tampered: changed param rm] no username');
ok(!$app->session->{'wubba'},      '[link - tampered: changed param rm] no session value wubba');
ok(!$app->session->{'tambourine'}, '[link - tampered: changed param rm] no session value tambourine');


# For some reason this prevents a core dump.
# - suspicion is that it has something to do with Apache::Session doing
#   at DESTROY time

undef $app;

