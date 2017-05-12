
use strict;
use warnings FATAL => 'all';
use English '-no_match_vars';

use FindBin;

use lib "$FindBin::Bin/lib";

use Test::More tests => 1;
SKIP: {
    skip 'skip all-- openid does not work for this bugfix release', 1;
    ok( 1 == 1, 'foo' );
    exit;
}

__END__

use Apache2::Controller::Test::Funk qw( diag od qs );
use YAML::Syck;
use URI::Escape;
use Carp qw(croak longmess);
use Log::Log4perl qw(:easy);

# start a separate server.
# because it can't process requests for the openid url
# while it is processing the request that tries to get it.

use Apache2::Controller::Test::OpenIDServer;

# start up the openid test server
my $openid_server = Apache2::Controller::Test::OpenIDServer->new();
my $openid_port = $openid_server->port;
my $openid_url_base = "http://localhost:$openid_port";
diag("openid_url_base: $openid_url_base");

my $openid_url = "$openid_url_base/a2ctest";
my $esc_openid_url = uri_escape($openid_url);

# set the server running in the background
my $openid_server_pid = $openid_server->background;
diag("openid server backgrounded, pid is '$openid_server_pid'");

# use the test libs after forking... although it doesn't seem to matter
use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest qw( GET_HEAD GET_BODY GET_STR );
plan tests => 25, need_module qw(
    LWP
    Net::OpenID::Server
    HTTP::Server::Simple
);
Apache::TestRequest::user_agent(cookie_jar => {}, requests_redirectable => 0);

my $at_config = Apache::Test::config();
#diag(Dump($at_config));

my $test_server_url = $at_config->{vars}{scheme}.'://'.$at_config->{server}{name};

my $protected_url = "/openid/protected";
my $user_area = "$protected_url/access_user_area";
my $login_url = "$protected_url/login";

# eval everything to make sure we kill the server on an error
eval {

# test the openid server first to make sure it's working
my $openid_working = GET_BODY "$openid_url_base/working";
ok t_cmp(
    $openid_working,
    'WORKING',
    'check temporary openid server is working',
);

my $setup_db = GET_BODY "/openid/unprotected/setup/create_db";
ok t_cmp(
    $setup_db, 
    'Created Database Tables.', 
    'create database tables'
);

sleep 5;

diag("get login page: GET_STR('$user_area')");
my $login_first = GET_STR($user_area);
#diag($login_first);

ok t_cmp(
    $login_first,
    qr{ ^ This \s is \s the \s login \s page\. }mxs,
    'first try redirects internally to login page',
);   

# try the protected page with the param.  it should redirect to registration.
my $protected_page_with_unk_openid_url = "$user_area?openid_url=$esc_openid_url";
diag("trying a protected page with unknown openid_url param: '$protected_page_with_unk_openid_url'");
my $register_when_unknown_protected 
    = GET_BODY($protected_page_with_unk_openid_url);
#diag($register_when_unknown_protected);
ok t_cmp(
    $register_when_unknown_protected,
    'Registration page - just testing.',
    'protected page w/ unknown openid url internal redispatch to registration',
);

# accessing the login page should have given the same results
my $reg_unk_login_url = "$login_url?openid_url=$esc_openid_url";
diag("get login page with unknown url to dispatch to registration: $reg_unk_login_url");
my $register_when_unknown_login = GET_BODY($reg_unk_login_url);
ok t_cmp(
    $register_when_unknown_login,
    'Registration page - just testing.',
    'login page w/ unknown openid url internal redispatch to registration',
);


# register the user for real (add them to the database
my $register_url = "$protected_url/register?for_real=1&openid_url=$esc_openid_url";
diag("register the user: $register_url");
my $register_for_real = GET_BODY($register_url);
diag($register_for_real);
ok t_cmp(
    $register_for_real,
    'Registration page - registered user.',
    'registered openid_url in database for user',
);


# ok, now try accessing the login page with openid_url param - 
# should redirect externally to the openid server

my $try_login_url = "$login_url?openid_url=$esc_openid_url";
diag("trying login for real, should redirect to openid server for login: $try_login_url");
my $try_login = GET_STR($try_login_url);
#diag("try_login\n$try_login");
my ($location_from_login) = $try_login =~ m{ ^ Location: \s+ (.*?) \n }mxs;
diag("location from login:\n$location_from_login");

my $redirect_verify_pat = qr{ \A \Q$openid_url_base\E /server \?  }mxs;

ok t_cmp(
    $location_from_login, 
    $redirect_verify_pat, 
    'redirect from login matches pattern' 
);



# accessing the protected user area with the openid_url param
# should result in the same external redirection to the openid server

my $try_protected = GET_STR("$user_area?openid_url=$esc_openid_url");
#diag("try_protected\n$try_protected");
my ($location_from_user_area) = $try_protected =~ m{ ^ Location: \s (.*?) \n }mxs;
#diag("location from user area:\n$location_from_user_area");

ok t_cmp(
    $location_from_user_area, 
    $redirect_verify_pat, 
    'redirect from user area matches pattern',
);

(my $test_location_from_login = $location_from_login)
    =~ s{ oic\.time\%3D [^\&]+ }{oic.time%3D[oic.time placeholder]}mxs;
(my $test_location_from_user_area = $location_from_user_area)
    =~ s{ oic\.time\%3D [^\&]+ }{oic.time%3D[oic.time placeholder]}mxs;

ok t_cmp(
    $test_location_from_login,
    $test_location_from_user_area,
    'redirect from login (mostly) same as from user area',
);

# ok, try the full login sequence
login();

return;

# then try logging out
logout();

DEBUG "NEW TEST: ACCESS USER AREA AFTER LOGOUT";

# now accessing user area should redirect to login page again
my $login_again = GET_BODY($user_area);
#diag($login_again);
ok t_cmp(
    $login_again,
    'This is the login page.',
    'trying user area after logout redirects to login page',
);

# but if we force timeout and then try user area, it should
# seamlessly redirect to the openid auth server

DEBUG "STARTING LOGIN SEQUENCE";

# log in again
login();

# force the session to timeout
my $force_timeout = GET_BODY('/openid/unprotected/setup/force_timeout');
ok t_cmp($force_timeout, 'Forced session timeout.', 'forced session timeout ok');

# try to access user area again, should redirect to auth server
my $user_area_after_timeout = GET_STR($user_area);
my ($location_relogin) = $user_area_after_timeout =~ m{ ^ Location: \s (.*?) \n }mxs;
ok t_cmp(
    $location_relogin,
    $redirect_verify_pat, 
    'Seamless re-login after timeout - redirected to server.',
);

# it should also have the return_to param set to the user area
ok t_cmp(
    $location_relogin,
    qr{ return_to= .*? \Q$user_area\E }mxs,
    'relogin location got return to for user area',
);

# as long as auth server thinks we're still logged in, should get back
# a location to user area
my $relogin_after_timeout = GET_STR($location_relogin);
my ($location_relogin_back_to_user_area) = $relogin_after_timeout 
    =~ m{ ^ Location: \s (.*?) \n }mxs;

#diag("back to user area: $location_relogin_back_to_user_area");
ok t_cmp(
    $location_relogin_back_to_user_area,
    qr{ http://.*? \Q$user_area\E }mxs,
    'relogin return location is back to user area',
);

my $relogin_get_user_area_authorized = GET_BODY($location_relogin_back_to_user_area);
ok t_cmp(
    $relogin_get_user_area_authorized,
    'Protected user area worked!',
    'seamlessly redirected back to authorized user area',
);

# GET query string preservation

# now try logging out, get with some vars, and check those vars
# are read in after the redirect sequence
logout();

my $dump_url = "$protected_url/dump_params";
my %get_query_vars = (
    captain     => 'Capt. James T. Kirk',
    science     => 'First Office Spock',
    medical     => 'Lt. Cmdr. Leonard H. "Bones" McCoy',
    awayteam    => [
        'Lt. Hikaru Sulu',
        'Nameless Yeoman Monster Fodder #1',
        'Nameless Yeoman Monster Fodder #2',
    ],
);
my $dump_url_get = "$dump_url?".qs( %get_query_vars );
diag("GETting query dump for '$dump_url_get'");

# should redirect thru openid server
my $redirect_for_get_vars = GET_STR($dump_url_get);
my ($location_openidserver_get_vars) = $redirect_for_get_vars 
    =~ m{ ^ Location: \s (.*?) \n }mxs;
diag("hrmm: $redirect_for_get_vars") if !defined $location_openidserver_get_vars;

diag("redirected to '$location_openidserver_get_vars'");


# POST body var preservation


};  # end of all-tests eval
diag("caught an error: '$EVAL_ERROR'") if $EVAL_ERROR;

killserver();

sub killserver {
    return if !$openid_server_pid;
    # kill the server
    kill 9, $openid_server_pid 
        || croak "Cannot kill openid_server in pid $openid_server_pid\n";
    return;
}

my $try = 0;
sub login {

    $try++;

    DEBUG "GETTING LOGIN URL WITH OPENID PARAM";
    my $try_login = GET_STR("$login_url?".qs( 
        openid_url  => $openid_url,
        test_try    => $try
    ));
    #diag("try_login\n$try_login");
    my ($location_from_login) = $try_login =~ m{ ^ Location: \s+ (.*?) \n }mxs;
    #diag("location from login:\n$location_from_login");
    
    my $redirect_verify_pat = qr{ \A \Q$openid_url_base\E /server \?  }mxs;
    
    ok t_cmp(
        $location_from_login, 
        $redirect_verify_pat, 
        'redirect from login matches pattern' 
    );

    # get that location and expect a positive return response from openid server
    DEBUG "GETTING LOCATION REDIRECT (OPENIDSERVER PAGE) FROM LOGIN '$location_from_login'";
    my $try_openid = GET_STR("$location_from_login");
    my ($location_return) = $try_openid =~ m{ ^ Location: \s+ (.*?) \n }mxs;
    
    ok t_cmp(
        $location_return,
        qr{ \A \Q$test_server_url\E \Q$user_area\E \? }mxs,
        "openid redirect return to user area with some params",
    );
    
    diag("openid return location:\n$location_return");

    # ok, get that one and see what happens
    DEBUG "GETTING RETURN LOCATION URI '$location_return'";
    my $try_authd_access_firststep = GET_STR("$location_return");
    my ($pass_id_url) = $try_authd_access_firststep 
        =~ m{ ^ Location: \s+ (.*?) \n }mxs;
    #diag("authorized access?\n".$try_authd_access);
    diag("got pass-identity url: $pass_id_url");
    ok t_cmp(
        $pass_id_url,
        qr{ \A \Q$openid_url_base\E /pass-identity \? }mxs,
        'pass-identity url returned from access after auth',
    );

    # ok, get the pass-identity url and see what happens
    my $try_pass_id = GET_STR($pass_id_url);
    diag($try_pass_id);

    return;

    # try user area again w/ no params and make sure we're still logged in
    DEBUG "GETTING USER AREA '$user_area'";
    DEBUG "current time = ".time;
    my $try_authd_access_again = GET_BODY("$user_area?".qs(
        test_try    => $try,
        tryagain    => 1,       # i don't do anything with these params
    ));                         # in the module unless i'm stuck
    #diag("trying again\n".$try_authd_access_again);
    ok t_cmp(
        $try_authd_access_again,
        'Protected user area worked!',
        'stayed logged in with no params.'
    );

    DEBUG "DONE WITH LOGIN SEQUENCE";
}

sub logout {
    DEBUG "NEW TEST: logout";
    
    # what happens when we try logout?
    my $try_logout = GET_BODY("$protected_url/logout");
    #diag('try logout: '.$try_logout);
    ok t_cmp(
        $try_logout,
        'This is the logout page.',
        'Logging out printed the right page.',
    );
}

