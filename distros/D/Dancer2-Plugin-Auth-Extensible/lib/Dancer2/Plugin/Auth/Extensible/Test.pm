package Dancer2::Plugin::Auth::Extensible::Test;

our $VERSION = '0.705';

=head1 NAME

Dancer2::Plugin::Auth::Extensible::Test - test suite for Auth::Extensible plugin

=cut

use warnings;
use strict;

use Carp qw(croak);
use Test::More;
use Test::Deep;
use Test::MockDateTime;
use Plack::Test;
use HTTP::Cookies;
use HTTP::Request::Common qw(GET POST);
use YAML ();

=head1 DESCRIPTION

Test suite for L<Dancer2::Plugin::Auth::Extensible> which can also be used
by external providers. If you have written your own provider then you really
want to use this since it should make sure your provider conforms as
L<Dancer2::Plugin::Auth::Extensible> expects it to. It will also save you
writing piles of tests yourself.

=head1 FUNCTIONS

=head2 runtests $psgi_app

This is the way to test your provider.

=head2 testme

This method no longer runs any tests but exists purely to force providers
trying to use the old tests to fail.

=cut

my $jar = HTTP::Cookies->new();

my %dispatch = (
    authenticate_user               => \&_authenticate_user,
    create_user                     => \&_create_user,
    get_user_details                => \&_get_user_details,
    login_logout                    => \&_login_logout,
    logged_in_user                  => \&_logged_in_user,
    logged_in_user_lastlogin        => \&_logged_in_user_lastlogin,
    logged_in_user_password_expired => \&_logged_in_user_password_expired,
    password_reset                  => \&_password_reset,
    require_login                   => \&_require_login,
    roles                           => \&_roles,
    update_current_user             => \&_update_current_user,
    update_user                     => \&_update_user,
    user_password                   => \&_user_password,
);

# Provider methods needed by plugin tests.
# These are assumed to be correct. If they are not then some provider tests
# should fail and we can fixup later.
my %dependencies = (
    create_user => [ 'get_user_details', 'create_user', 'set_user_details', ],
    get_user_details => ['get_user_details'],
    logged_in_user   => ['get_user_details'],
    logged_in_user_lastlogin => ['create_user','record_lastlogin'],
    logged_in_user_password_expired =>
      [ 'get_user_details', 'password_expired' ],
    password_reset      => ['get_user_by_code', 'set_user_details'],
    require_login       => ['get_user_details'],
    roles               => ['get_user_roles' ],
    update_current_user => ['set_user_details'],
    update_user         => ['set_user_details'],
    user_password =>
      [ 'get_user_by_code', 'authenticate_user', 'set_user_details' ],
);

my ( $test, $trap );

sub testme {
    BAIL_OUT "Please upgrade your provider to the latest version. Dancer2::Plugin::Auth::Extensible no longer supports the old \"testme\" tests.";
}

# so test can check
my @provider_can;

sub runtests {
    my $app = shift;

    $test = Plack::Test->create($app);
    $trap = TestApp->dancer_app->logger_engine->trapper;

    my $res = get('/provider_can');
    BAIL_OUT "Unable to determine what methods the provider supports"
      unless $res->is_success;

    my $ret = YAML::Load $res->content;

    BAIL_OUT "Unexpected response to /provider_can"
      unless ref($ret) eq 'ARRAY';

    @provider_can = @$ret;

    my @to_test = ($ENV{D2PAE_TEST_ONLY}) || keys %dispatch;

    foreach my $test ( @to_test ) {
        my @missing;
        foreach my $dep ( @{ $dependencies{$test} || [] } ) {
            push @missing, $dep if !grep { $_ eq $dep } @provider_can;
        }
      SKIP: {
            skip "Provider $test tests as provider is missing methods: "
              . join( ", ", @missing ), 1
              if @missing;

            # for safety in case one set of tests doesn't clean up carefully
            $jar->clear;

            subtest "Plugin $test tests" => $dispatch{$test};
        }
    }
}

sub get {
    my $uri = shift;
    my $req = GET "http://localhost$uri";
    $jar->add_cookie_header($req);
    my $res = $test->request($req);
    $jar->extract_cookies($res);
    return $res;
}

sub post {
    my $uri    = shift;
    my $params = shift || [];
    my $req    = POST "http://localhost$uri", $params;
    $jar->add_cookie_header($req);
    my $res = $test->request($req);
    $jar->extract_cookies($res);
    return $res;
}

#------------------------------------------------------------------------------
#
#  authenticate_user
#
#------------------------------------------------------------------------------

sub _authenticate_user {
    my ($res, $data, $logs);

    # no args

    $trap->read;
    $res = post('/authenticate_user');
    ok $res->is_success, "/authenticate_user with no params is_success";
    cmp_deeply YAML::Load( $res->content ), [ 0, undef ],
      "... and returns expected response";
    cmp_deeply $trap->read,
      superbagof(
        {
            formatted => ignore(),
            level     => 'debug',
            message => 'before_authenticate_user{"password":null,"realm":null,"username":null}'
        },
        {
            formatted => ignore(),
            level     => 'debug',
            message => 'after_authenticate_user{"errors":[],"password":null,"realm":null,"success":0,"username":null}'
        }
      ),
      "... and we see expected hook output in logs.";

    # empty username and password

    $res = post('/authenticate_user',[username=>'',password=>'']);
    ok $res->is_success,
      "/authenticate_user with empty username and password is_success";
    cmp_deeply YAML::Load( $res->content ), [ 0, undef ],
      "... and returns expected response";
    cmp_deeply $trap->read,
      superbagof(
        {
            formatted => ignore(),
            level     => 'debug',
            message => 'before_authenticate_user{"password":"","realm":null,"username":""}'
        },
        {
            formatted => ignore(),
            level     => 'debug',
            message => 'after_authenticate_user{"errors":[],"password":"","realm":null,"success":0,"username":""}'
        }
      ),
      "... and we see expected hook output in logs.";

    # good username, bad password and no realm

    $res = post('/authenticate_user',[username=>'dave',password=>'badpwd']);
    ok $res->is_success,
      "/authenticate_user with user dave, bad password and no realm success";
    cmp_deeply YAML::Load( $res->content ), [ 0, undef ],
      "... and returns expected response";
    $logs = $trap->read;
    cmp_deeply $logs,
      superbagof(
        {
            formatted => ignore(),
            level     => 'debug',
            message => 'before_authenticate_user{"password":"badpwd","realm":null,"username":"dave"}'
        },
        {
            formatted => ignore(),
            level     => 'debug',
            message   => re(qr/Attempting.+dave.+realm config2/)
        },
        {
            formatted => ignore(),
            level     => 'debug',
            message   => re(qr/Attempting.+dave.+realm config3/)
        },
        {
            formatted => ignore(),
            level     => 'debug',
            message   => re(qr/Attempting.+dave.+realm config1/)
        },
        {
            formatted => ignore(),
            level     => 'debug',
            message => 'after_authenticate_user{"errors":[],"password":"badpwd","realm":null,"success":0,"username":"dave"}'
        }
      ),
      "... and we see expected hook output in logs and realms checked."
      or diag explain $logs;

    # good username, good password but wrong realm

    $res = post( '/authenticate_user',
        [ username => 'dave', password => 'beer', realm => 'config2' ] );
    ok $res->is_success,
      "/authenticate_user with user dave, good password but wrong realm success";
    cmp_deeply YAML::Load( $res->content ), [ 0, undef ],
      "... and returns expected response";

    $logs = $trap->read;
    cmp_deeply $logs,
      superbagof(
        {
            formatted => ignore(),
            level     => 'debug',
            message => 'before_authenticate_user{"password":"beer","realm":"config2","username":"dave"}'
        },
        {
            formatted => ignore(),
            level     => 'debug',
            message   => re(qr/Attempting.+dave.+realm config2/)
        },
        {
            formatted => ignore(),
            level     => 'debug',
            message => 'after_authenticate_user{"errors":[],"password":"beer","realm":null,"success":0,"username":"dave"}'
        }
      ),
      "... and we see expected hook output in logs and realm config2 checked"
      or diag explain $logs;

    cmp_deeply $logs,
      noneof(
        {
            formatted => ignore(),
            level     => 'debug',
            message   => re(qr/Attempting.+dave.+realm config1/)
        },
        {
            formatted => ignore(),
            level     => 'debug',
            message   => re(qr/Attempting.+dave.+realm config3/)
        },
      ),
      "... and the other realms were not checked."
      or diag explain $logs;

    # good username, good password and good realm

    $res = post( '/authenticate_user',
        [ username => 'dave', password => 'beer', realm => 'config1' ] );
    ok $res->is_success,
      "/authenticate_user with user dave, good password and good realm success";
    cmp_deeply YAML::Load( $res->content ), [ 1, "config1" ],
      "... and returns expected response";

    $logs = $trap->read;
    cmp_deeply $logs,
      superbagof(
        {
            formatted => ignore(),
            level     => 'debug',
            message => 'before_authenticate_user{"password":"beer","realm":"config1","username":"dave"}'
        },
        {
            formatted => ignore(),
            level     => 'debug',
            message   => re(qr/Attempting.+dave.+realm config1/)
        },
        {
            formatted => ignore(),
            level     => 'debug',
            message   => re(qr/config1 accepted user dave/),
        },
        {
            formatted => ignore(),
            level     => 'debug',
            message => 'after_authenticate_user{"errors":[],"password":"beer","realm":"config1","success":1,"username":"dave"}'
        }
      ),
      "... and we see expected hook output in logs and only one realm checked"
      or diag explain $logs;

    cmp_deeply $logs,
      noneof(
        {
            formatted => ignore(),
            level     => 'debug',
            message   => re(qr/Attempting.+dave.+realm config2/)
        },
        {
            formatted => ignore(),
            level     => 'debug',
            message   => re(qr/Attempting.+dave.+realm config3/)
        },
      ),
      "... and the other realms were not checked."
      or diag explain $logs;

    # good username, good password and no realm

    $res = post( '/authenticate_user',
        [ username => 'dave', password => 'beer' ] );
    ok $res->is_success,
      "/authenticate_user with user dave, good password and no realm success";
    cmp_deeply YAML::Load( $res->content ), [ 1, "config1" ],
      "... and returns expected response";

    $logs = $trap->read;
    cmp_deeply $logs,
      superbagof(
        {
            formatted => ignore(),
            level     => 'debug',
            message => 'before_authenticate_user{"password":"beer","realm":null,"username":"dave"}'
        },
        {
            formatted => ignore(),
            level     => 'debug',
            message   => re(qr/Attempting.+dave.+realm config2/)
        },
        {
            formatted => ignore(),
            level     => 'debug',
            message   => re(qr/Attempting.+dave.+realm config3/)
        },
        {
            formatted => ignore(),
            level     => 'debug',
            message   => re(qr/Attempting.+dave.+realm config1/)
        },
        {
            formatted => ignore(),
            level     => 'debug',
            message   => re(qr/config1 accepted user dave/),
        },
        {
            formatted => ignore(),
            level     => 'debug',
            message => 'after_authenticate_user{"errors":[],"password":"beer","realm":"config1","success":1,"username":"dave"}'
        }
      ),
      "... and we see expected hook output in logs and 3 realms checked."
      or diag explain $logs;

    # good username, good password and no realm using 2nd realm by priority

    $res = post( '/authenticate_user',
        [ username => 'bananarepublic', password => 'whatever' ] );
    ok $res->is_success,
      "/authenticate_user with user bananarepublic, good password and no realm success";
    cmp_deeply YAML::Load( $res->content ), [ 1, "config3" ],
      "... and returns expected response";

    $logs = $trap->read;
    cmp_deeply $logs,
      superbagof(
        {
            formatted => ignore(),
            level     => 'debug',
            message => 'before_authenticate_user{"password":"whatever","realm":null,"username":"bananarepublic"}'
        },
        {
            formatted => ignore(),
            level     => 'debug',
            message   => re(qr/Attempting.+bananarepublic.+realm config2/)
        },
        {
            formatted => ignore(),
            level     => 'debug',
            message   => re(qr/Attempting.+bananarepublic.+realm config3/)
        },
        {
            formatted => ignore(),
            level     => 'debug',
            message   => re(qr/config3 accepted user bananarepublic/),
        },
        {
            formatted => ignore(),
            level     => 'debug',
            message => 'after_authenticate_user{"errors":[],"password":"whatever","realm":"config3","success":1,"username":"bananarepublic"}'
        }
      ),
      "... and we see expected hook output in logs and 2 realms checked"
      or diag explain $logs;

    cmp_deeply $logs,
      noneof(
        {
            formatted => ignore(),
            level     => 'debug',
            message   => re(qr/Attempting.+bananarepublic.+realm config1/)
        },
      ),
      "... and we don't see realm config1 checked."
      or diag explain $logs;

    # quick pairwise for coverage
    foreach my $username ( undef, +{}, '', 'username' ) {
        foreach my $password ( undef, +{}, '', 'password' ) {
            $res = post( '/authenticate_user',
                [ username => $username, password => $password ] );
            ok $res->is_success, "/authenticate_user with user dave, bad password and no realm success";
            cmp_deeply YAML::Load( $res->content ), [ 0, undef ],
              "... and returns expected response";
        }
    }
}

#------------------------------------------------------------------------------
#
#  create_user
#
#------------------------------------------------------------------------------

sub _create_user {
    my ( $res, $logs );

    # create user with no args should die since we have > 1 realm

    $trap->read;

    $res = post('/create_user');
    is $res->code, 500,
      "/create_user with no params is 500 due to > 1 realm.";

    $logs = $trap->read;
    cmp_deeply $logs,
      [
        {
            formatted => ignore(),
            level     => 'error',
            message   => re(
                qr/Realm must be specified when more than one realm configured/
            ),
        }
      ],
      "... and error about needing realm was logged.";

    # create user with no password

    $res = post( "/create_user",
        [ username => 'createusernopw', realm => 'config1' ] );
    ok $res->is_success, "/create_user with no password is_success";

    for my $realm (qw/config1 config2/) {

        # create a user

        my $data = [
            username => 'newuser',
            password => "pish_$realm",
            realm    => $realm,
        ];

        $res = post( "/create_user", $data );
        ok $res->is_success, "/create_user newuser in realm $realm is success"
          or diag explain $trap->read;
        is $res->content, 1, "... and response content shows create success";

        $logs = $trap->read;
        cmp_deeply $logs,
          superbagof(
            {
                formatted => ignore(),
                level   => 'debug',
                message => qq(before_create_user{"password":"pish_$realm","realm":"$realm","username":"newuser"}),
            },
            {
                formatted => ignore(),
                level     => 'debug',
                message   => 'after_create_user,newuser,1,no',
            }
          ),
          "... and we see expected before/after hook logs.";

        # try creating same user a second time

        $res = post( "/create_user", $data );
        ok $res->is_success,
          "/create_user newuser *again* in realm $realm is success"
          or diag explain $trap->read;
        is $res->content, 0, "... and response content shows create failed";

        $logs = $trap->read;
        cmp_deeply $logs,
          superbagof(
            {
                formatted => ignore(),
                level   => 'debug',
                message => qq(before_create_user{"password":"pish_$realm","realm":"$realm","username":"newuser"}),
            },
            {
                formatted => ignore(),
                level     => 'error',
                message   => re(qr/$realm provider threw error/),
            },
            {
                formatted => ignore(),
                level     => 'debug',
                message   => re(qr/after_create_user,newuser,0,yes/),
            }
          ),
          "... and we see expected before/after hook logs."
          or diag explain $logs;

        # Then try logging in with that user

        $trap->read;    # clear logs

        $res = post( '/login', $data );

        is( $res->code, 302, 'Login with newly created user succeeds' )
          or diag explain $trap->read;

        my $logs = $trap->read;
        cmp_deeply $logs,
          superbagof(
            {
                formatted => ignore(),
                level     => 'debug',
                message   => "$realm accepted user newuser"
            }
          ),
          "... and we see expected message in logs."
          or diag explain $res;

        is get('/loggedin')->content, "You are logged in",
          "... and checking /loggedin route shows we are logged in";

        get('/logout');
    }

    # create user with `email_welcome` so we can test reset code

    $Dancer2::Plugin::Auth::Extensible::Test::App::data = undef;

    $res = post(
        "/create_user",
        [
            username      => 'newuserwithcode',
            realm         => 'config1',
            email_welcome => 1,
        ]
    );

    is $res->code, 200, "/create_user with welcome_send=>1 response is 200"
      or diag explain $trap->read;

    # the args passed to 'welcome_send' sub
    my $args = $Dancer2::Plugin::Auth::Extensible::Test::App::data;
    like $args->{code}, qr/^\w{32}$/,
      "... and we have a reset code in the email";
}

#------------------------------------------------------------------------------
#
#  get_user_details
#
#------------------------------------------------------------------------------

sub _get_user_details {
    my ( $logs, $res );

    # no args

    $res = post('/get_user_details');
    ok $res->is_success, "/get_user_details with no params is_success";
    is $res->content, 0, "... and no user was returned.";

    # unknown user

    $trap->read;

    $res = post( '/get_user_details', [ username => 'NoSuchUser' ] );
    ok $res->is_success, "/get_user_details with unknown user is_success";
    is $res->content, 0, "... and no user was returned.";

    $logs = $trap->read;
    cmp_deeply $logs, superbagof(
        {
            formatted => ignore(),
            level => 'debug',
            message => 'Attempting to find user NoSuchUser in realm config2',
        },
        {
            formatted => ignore(),
            level => 'debug',
            message => 'Attempting to find user NoSuchUser in realm config3',
        },
        {
            formatted => ignore(),
            level => 'debug',
            message => 'Attempting to find user NoSuchUser in realm config1',
        },
    ), "... and we see logs we expect."
        or diag explain $logs;

    # known user but wrong realm

    $trap->read;

    $res =
      post( '/get_user_details', [ username => 'dave', realm => 'config2' ] );
    ok $res->is_success, "/get_user_details dave config2 is_success";
    is $res->content, 0, "... and no user was returned (wrong realm).";

    $logs = $trap->read;
    cmp_deeply $logs, superbagof(
        {
            formatted => ignore(),
            level => 'debug',
            message => 'Attempting to find user dave in realm config2',
        },
    ), "... and we see logs we expect" or diag explain $logs;

    cmp_deeply $logs, noneof(
        {
            formatted => ignore(),
            level => 'debug',
            message => 'Attempting to find user dave in realm config3',
        },
        {
            formatted => ignore(),
            level => 'debug',
            message => 'Attempting to find user dave in realm config1',
        },
    ), "... and none of the ones we don't expect." or diag explain $logs;

    # known user unspecified realm

    $trap->read;

    $res =
      post( '/get_user_details', [ username => 'dave' ] );
    ok $res->is_success, "/get_user_details dave in any realm is_success";
    like $res->content, qr/David Precious/,
      "... and correct user was returned.";

    # known user correct realm

    $trap->read;

    $res =
      post( '/get_user_details', [ username => 'dave', realm => 'config1' ] );
    ok $res->is_success, "/get_user_details dave in config1 is_success";
    like $res->content, qr/David Precious/,
      "... and correct user was returned.";

};

#------------------------------------------------------------------------------
#
#  login_logout
#
#  also includes some auth_provider tests
#
#------------------------------------------------------------------------------

sub _login_logout {
    my ( $data, $res, $logs );

    # auth_provider with no args

    $trap->read;
    $res = post('/auth_provider');
    is $res->code, 500, "auth_provider with no args dies";
    $logs = $trap->read;
    cmp_deeply $logs, superbagof(
        { formatted => ignore(),
            level => 'error',
            message => re(qr/auth_provider needs realm or/),
        }
    ), "... and correct error message is seen in logs." or diag explain $logs;

    # auth_provider with non-existant realm

    $trap->read;
    $res = post('/auth_provider', [realm => 'NoSuchRealm']);
    is $res->code, 500, "auth_provider with non-existant realm dies";
    $logs = $trap->read;
    cmp_deeply $logs, superbagof(
        { formatted => ignore(),
            level => 'error',
            message => re(qr/Invalid realm NoSuchRealm/),
        }
    ), "... and correct error message is seen in logs." or diag explain $logs;

    # auth_provider with good realm

    $res = post('/auth_provider', [realm => 'config1']);
    ok $res->is_success, "auth_provider with good realm lives"
      or diag explain $trap->read;

    # Check that login route doesn't match any request string with '/login'.

    $trap->read;
    $res = get('/foo/login');
    is $res->code, 404, "'/foo/login' URL not matched by login route regex."
      or diag explain $trap->read;

    # Now, without being logged in, check we can access the index page,
    # but not stuff we need to be logged in for:

    $res = get('/');
    ok $res->is_success, "Index always accessible - GET / success";
    is $res->content,    'Index always accessible',
          "...and we got expected content.";

    # check session_data when not logged in

    $res = get('/session_data');
    ok $res->is_success, "/session_data is_success";
    $data = YAML::Load $res->content;
    ok !defined $data->{logged_in_user},
      "... and logged_in_user is not set in the session";
    ok !defined $data->{logged_in_user_realm},
      "... and logged_in_user_realm is not set in the session.";

    # get /login

    $res = get('/login');
    ok $res->is_success, "GET /login is_success";
    like $res->content, qr/input.+name="password"/,
      "... and we have the login page.";

    # login page has password reset section (or not)
    if ( grep { $_ eq 'get_user_by_code' } @provider_can ) {
        like $res->content,
        qr/Enter your username to obtain an email to reset your password/,
        "... which has password reset option (reset_password_handler=>1).";
    }
    else {
        unlike $res->content,
        qr/Enter your username to obtain an email to reset your password/,
        "... which has *no* password reset option (reset_password_handler=>0)";

        # code coverage 'Reset password code submitted?' section of default
        # get /login route.
        $res = get('/login/12345678901234567890123456789012');
        ok $res->is_success, "... and try a get /login/<code> is_success";
    }

    # post empty /login

    $res = post('/login');
    ok $res->is_success, "POST /login is_success";
    like $res->content, qr/input.+name="password"/,
      "... and we have the login page";
    like $res->content, qr/LOGIN FAILED/,
      "... and we see LOGIN FAILED";

    # check session_data again

    $res = get('/session_data');
    ok $res->is_success, "/session_data is_success";
    $data = YAML::Load $res->content;
    ok !defined $data->{logged_in_user},
      "... and logged_in_user is not set in the session";
    ok !defined $data->{logged_in_user_realm},
      "... and logged_in_user_realm is not set in the session.";

    # post good /login

    $res = post( '/login', [ username => 'dave', password => 'beer' ] );
    ok $res->is_redirect, "POST /login with good username/password is_redirect";
    is $res->header('location'), 'http://localhost/',
      "... and redirect location is correct.";

    # check session_data again

    $res = get('/session_data');
    ok $res->is_success, "/session_data is_success";
    $data = YAML::Load $res->content;
    is $data->{logged_in_user}, 'dave',
      "... and session logged_in_user is set to dave";
    is $data->{logged_in_user_realm}, 'config1',
      "... and session logged_in_user_realm is set to config1.";

    # get /login whilst already logged in

    $res = get('/login');
    ok $res->is_redirect, "GET /login whilst logged in is redirected."
      or diag explain $res;
    is $res->header('location'), 'http://localhost/',
      "... and redirect location is correct.";

    # get /login whilst already logged in with return_url set

    $res = get('/login?return_url=/foo');
    ok $res->is_redirect,
      "GET /login whilst logged in with return_url set in query is redirected.";
    is $res->header('location'), 'http://localhost/foo',
      "... and redirect location is correct.";

    # auth_provider with no realm but user is logged in

    $res = post('/auth_provider');
    ok $res->is_success, "auth_provider with *no* realm lives"
      or diag explain $trap->read;

    # get /logout

    $res = get('/logout');
    ok $res->is_redirect, "GET /logout is_redirect" or diag explain $res;
    is $res->header('location'), 'http://localhost/',
      "... and redirect location is correct.";

    # check session_data again

    $res = get('/session_data');
    ok $res->is_success, "/session_data is_success";
    $data = YAML::Load $res->content;
    ok !defined $data->{logged_in_user},
      "... and logged_in_user is not set in the session";
    ok !defined $data->{logged_in_user_realm},
      "... and logged_in_user_realm is not set in the session.";

    # post good /login

    $res = post( '/login', [ username => 'dave', password => 'beer' ] );
    ok $res->is_redirect, "POST /login with good username/password is_redirect";
    is $res->header('location'), 'http://localhost/',
      "... and redirect location is correct.";

    # check session_data again

    $res = get('/session_data');
    ok $res->is_success, "/session_data is_success";
    $data = YAML::Load $res->content;
    is $data->{logged_in_user}, 'dave',
      "... and session logged_in_user is set to dave" or diag explain $data;
    is $data->{logged_in_user_realm}, 'config1',
      "... and session logged_in_user_realm is set to config1.";

    # POST /logout with return_url

    $res = post('/logout', [ return_url => '/foo/bar' ] );
    ok $res->is_redirect, "POST /logout with return_url /foo/bar is_redirect"
      or diag explain $res;
    is $res->header('location'), 'http://localhost/foo/bar',
      "... and redirect location /foo/bar is correct.";

    # check session_data again

    $res = get('/session_data');
    ok $res->is_success, "/session_data is_success";
    $data = YAML::Load $res->content;
    ok !defined $data->{logged_in_user},
      "... and logged_in_user is not set in the session";
    ok !defined $data->{logged_in_user_realm},
      "... and logged_in_user_realm is not set in the session.";

    # Now check we can log in as a user whose password is stored hashed:

    {
        $trap->read;    # clear logs

        my $res = post(
            '/login',
            {
                username => 'hashedpassword',
                password => 'password'
            }
        );

        is( $res->code, 302, 'Login as user with hashed password succeeds' )
          or diag explain $trap->read;

        my $logs = $trap->read;
        cmp_deeply $logs,
          superbagof(
            {
                formatted => ignore(),
                level     => 'debug',
                message   => 'config2 accepted user hashedpassword'
            }
          ),
          "... and we see expected message in logs.";

        is get('/loggedin')->content, "You are logged in",
          "... and checking /loggedin route shows we are logged in";
    }

    # And that now we're logged in again, we can access protected pages

    {
        $trap->read;    # clear logs

        my $res = get('/loggedin');

        is( $res->code, 200, 'Can access /loggedin now we are logged in again' )
          or diag explain $trap->read;
    }

    # Check that the redirect URL can be set when logging in

    {
        $trap->read;    # clear logs

        # make sure we're logged out
        get('/logout');

        my $res = post(
            '/login',
            {
                username   => 'dave',
                password   => 'beer',
                return_url => '/foobar',
            }
        );

        is( $res->code, 302, 'Status code for login with return_url' )
          or diag explain $trap->read;

        is( $res->headers->header('Location'),
            'http://localhost/foobar',
            'Redirect after login to given return_url works' );

        my $logs = $trap->read;
        cmp_deeply $logs,
          superbagof(
            {
                formatted => ignore(),
                level     => 'debug',
                message   => 'config1 accepted user dave'
            }
          ),
          "... and we see expected message in logs." or diag explain $logs;

        is get('/loggedin')->content, "You are logged in",
          "... and checking /loggedin route shows we are logged in";
    }

    # Now, log out again

    {
        $trap->read;    # clear logs

        my $res = post('/logout');
        is( $res->code, 302, 'Logging out returns 302' )
          or diag explain $trap->read;

        is( $res->headers->header('Location'),
            'http://localhost/',
            '/logout redirected to / (exit_page) after logging out' );
    }

    # /login/denied page

    {
        my $res = get('/login/denied');
        is $res->code, '403', "GET /login/denied results in a 403 denied code";
        like $res->content, qr/Permission Denied/,
          "... and we have Permission Denied text in page";
    }
}

#------------------------------------------------------------------------------
#
#  logged_in_user
#
#------------------------------------------------------------------------------

sub _logged_in_user {
    my ( $data, $res );

    # check logged_in_user when not logged in

    $res = get('/logged_in_user');
    ok $res->is_success, "/logged_in_user is_success";
    $data = YAML::Load $res->content;
    is $data, 'none', "... and there is no logged_in_user."
      or diag explain $data;

    # post empty /login

    $res = post('/login');
    ok $res->is_success, "POST /login is_success";
    like $res->content, qr/input.+name="password"/,
      "... and we have the login page";
    like $res->content, qr/LOGIN FAILED/,
      "... and we see LOGIN FAILED";

    # check logged_in_user again

    $res = get('/logged_in_user');
    ok $res->is_success, "/logged_in_user is_success";
    $data = YAML::Load $res->content;
    is $data, 'none', "... and there is no logged_in_user."
      or diag explain $data;

    # post good /login

    $res = post( '/login', [ username => 'dave', password => 'beer' ] );
    ok $res->is_redirect, "POST /login with good username/password is_redirect";
    is $res->header('location'), 'http://localhost/',
      "... and redirect location is correct.";

    # check logged_in_user again

    $res = get('/logged_in_user');
    ok $res->is_success, "/logged_in_user is_success";
    $data = YAML::Load $res->content;
    is $data->{name}, 'David Precious',
      "... and we see dave's name is David Precious." or diag explain $data;

    # check logged_in_user gets cached (coverage)

    $res = get('/logged_in_user_twice');
    ok $res->is_success, "/logged_in_user_twice is_success";
    $data = YAML::Load $res->content;
    is $data->{name}, 'David Precious',
      "... and we see dave's name is David Precious." or diag explain $data;

    # get /logout

    $res = get('/logout');
    ok $res->is_redirect, "GET /logout is_redirect" or diag explain $res;
    is $res->header('location'), 'http://localhost/',
      "... and redirect location is correct.";

    # check logged_in_user again

    $res = get('/logged_in_user');
    ok $res->is_success, "/logged_in_user is_success";
    $data = YAML::Load $res->content;
    is $data, 'none', "... and there is no logged_in_user."
      or diag explain $data;
}

#------------------------------------------------------------------------------
#
#  logged_in_user_lastlogin
#
#------------------------------------------------------------------------------

sub _logged_in_user_lastlogin {
    my ( $res, $session );

    # create a new user for test so we are sure lastlogin has not been set

    $res = post(
        "/create_user",
        [
            username      => 'lastlogin1',
            password      => 'lastlogin2',
            realm         => 'config1',
        ]
    );
    ok $res->is_success, "create_user lastlogin1 call is_success";

    # check the session for logged_in_user_lastlogin

    $res = get('/session_data');
    ok $res->is_success, "get /session_data is_success";
    $session = YAML::Load $res->content;
    ok !defined $session->{logged_in_user_lastlogin},
      "... and logged_in_user_lastlogin is not set in the session.";

    # we cannot reach require_login routes

    $res = get('/loggedin');
    ok $res->is_redirect, "GET /loggedin causes redirect";
    is $res->header('location'),
      'http://localhost/login?return_url=%2Floggedin',
      "... and we're redirected to /login with return_url=/loggedin.";

    # login

    $res =
      post( '/login', [ username => 'lastlogin1', password => 'lastlogin2' ] );
    ok $res->is_redirect, "POST /login with with new user is_redirect";
    is $res->header('location'), 'http://localhost/',
      "... and redirect location is correct.";

    # check we can reach restricted page

    $res = get('/loggedin');
    ok $res->is_success, "GET /loggedin is_success now we're logged in";
    is $res->content, "You are logged in", "... and we can see page content.";

    # check the session for logged_in_user_lastlogin

    $res = get('/session_data');
    ok $res->is_success, "get /session_data is_success";
    $session = YAML::Load $res->content;
    ok !defined $session->{logged_in_user_lastlogin},
      "... and logged_in_user_lastlogin is still not set in the session.";

    # check logged_in_user_lastlogin method

    $res = get('/logged_in_user_lastlogin');
    ok $res->is_success, "get /logged_in_user_lastlogin is_success";
    is $res->content, "not set",
      "... and logged_in_user_lastlogin returns undef"
      or diag explain $res->content;

    # logout

    $res = get('/logout');
    ok $res->is_redirect, "/logout is_success";

    # login again and now logged_in_user_lastlogin should be set

    $res =
      post( '/login', [ username => 'lastlogin1', password => 'lastlogin2' ] );
    ok $res->is_redirect, "POST /login with with new user is_redirect";
    is $res->header('location'), 'http://localhost/',
      "... and redirect location is correct.";

    # check we can reach restricted page

    $res = get('/loggedin');
    ok $res->is_success, "GET /loggedin is_success now we're logged in";
    is $res->content, "You are logged in", "... and we can see page content.";

    # check the session for logged_in_user_lastlogin

    $res = get('/session_data');
    ok $res->is_success, "get /session_data is_success";
    $session = YAML::Load $res->content;
    ok defined $session->{logged_in_user_lastlogin},
      "... and logged_in_user_lastlogin is still not set in the session."
      or diag explain $session;
    like $session->{logged_in_user_lastlogin}, qr/^\d+$/,
      "... and session logged_in_user_lastlogin looks like an epoch time.";

    # check logged_in_user_lastlogin method

    $res = get('/logged_in_user_lastlogin');
    ok $res->is_success, "get /logged_in_user_lastlogin is_success";
    my $date = DateTime->now->ymd;
    is $res->content, $date,
      "... and logged_in_user_lastlogin is $date.";

    # cleanup
    get('/logout');
}

#------------------------------------------------------------------------------
#
#  logged_in_user_password_expired
#
#------------------------------------------------------------------------------

sub _logged_in_user_password_expired {
    my $res;

    my $data = [
        username => 'pwdexpired1',
        password => 'pwd1',
        realm    => 'config1'
    ];

    on '2016-10-01 00:00:00' => sub {
        $res = post( '/create_user',$data);
        ok $res->is_success, "create user pwdexpired1 is success on 2016-10-01";
        is $res->content, 1,
          "... and it seems user was created based on response.";

        $res = get('/logged_in_user_password_expired');
        is $res->content, 'no',
          "... and before login logged_in_user_password_expired is false.";

        post('/login', $data);
        $res = get('/loggedin');
        ok $res->is_success, "User is now logged in";

        $res = get('/logged_in_user_password_expired');
        is $res->content, 'no',
          "... and logged_in_user_password_expired is false.";
    };

    note "... time passes ...";

    on '2016-11-01 00:00:00' => sub {

        $res = get('/logged_in_user_password_expired');
        is $res->content, 'yes',
          "... and 30 days later logged_in_user_password_expired is true.";

        post('/logout');
    };
}

#------------------------------------------------------------------------------
#
#  password_reset
#
#------------------------------------------------------------------------------

sub _password_reset {
    my ( $res, $code );

    # request password reset with non-existant user

    $Dancer2::Plugin::Auth::Extensible::Test::App::data = undef;
    $trap->read;

    $res = post( '/login',
        [ username_reset => 'NoSuchUser', submit_reset => 'truthy value' ] );

    ok $res->is_success, "POST /login with password reset request is_success"
      or diag explain $res;

    like $res->content, qr/A password reset request has been sent/,
      "... and we see \"A password reset request has been sent\" in page"
      or diag explain $trap->read;

    ok !defined $Dancer2::Plugin::Auth::Extensible::Test::App::data,
      "... and password_reset_send_email was not called."
      or diag explain $Dancer2::Plugin::Auth::Extensible::Test::App::data;

    # call /login/$code with bad code

    $res = get("/login/12345678901234567890123456789012");

    ok $res->is_success, "GET /login/<code> with bad code is_success"
      or diag explain $res;

    like $res->content, qr/You need to log in to continue/,
      "... and we have the /login page.";

    # request password reset with valid user

    $Dancer2::Plugin::Auth::Extensible::Test::App::data = undef;
    $trap->read;

    $res = post( '/login',
        [ username_reset => 'dave', submit_reset => 'truthy value' ] );

    ok $res->is_success, "POST /login with password reset request is_success"
      or diag explain $res;

    like $res->content, qr/A password reset request has been sent/,
      "... and we see \"A password reset request has been sent\" in page"
      or diag explain $trap->read;

    cmp_deeply $Dancer2::Plugin::Auth::Extensible::Test::App::data,
      {
        called => 1,
        code   => re(qr/\w+/),
        email  => ignore(),
      },
      "... and password_reset_send_email received code and email.";

    $code = $Dancer2::Plugin::Auth::Extensible::Test::App::data->{code};

    # get /login/$code

    $trap->read;
    $res = get("/login/$code");

    ok $res->is_success, "GET /login/<code> with good code is_success"
      or diag explain $res;

    like $res->content,
      qr/Please click the button below to reset your password/,
      "... and we have the /login page with reset password link.";

    # post /login/$code with bad code

    $trap->read;
    $res = post(
        "/login/12345678901234567890123456789012",
        [ confirm_reset => "Reset password" ]
    );
    ok $res->is_success, "POST /login/<code> with bad code is_success",
      or diag explain $res;
    unlike $res->content, qr/Your new password is \w{8}\</,
      "... and we are NOT given a new password";
    like $res->content, qr/LOGIN FAILED/, "... but see LOGIN FAILED.";

    # post /login/$code with good code

    $trap->read;
    $res = post( "/login/$code", [ confirm_reset => "Reset password" ] );
    ok $res->is_success, "POST /login/<code> with good code is_success",
      or diag explain $res;
    like $res->content, qr/Your new password is \w{8}\</,
      "... and we are given a new password."
      or diag explain $trap->read;

    # reset dave's password for later tests

    $res =
      post( '/user_password', [ username => 'dave', new_password => 'beer' ] );
    is $res->content, "dave", "Reset dave's password to beer";

}

#------------------------------------------------------------------------------
#
#  require_login
#
#------------------------------------------------------------------------------

sub _require_login {
    my ( $res, $logs );

    # check open / is ok

    $res = get('/');
    ok $res->is_success, "GET / is success - no login required";

    # we cannot reach require_login routes

    $res = get('/loggedin');
    ok $res->is_redirect, "GET /loggedin causes redirect";
    is $res->header('location'),
      'http://localhost/login?return_url=%2Floggedin',
      "... and we're redirected to /login with return_url=/loggedin.";

    # regex route when not logged in

    $res = get('/regex/a');
    ok $res->is_redirect, "GET /regex/a causes redirect";
    is $res->header('location'),
      'http://localhost/login?return_url=%2Fregex%2Fa',
      "... and we're redirected to /login with return_url=/regex/a.";

    # login

    $res = post( '/login', [ username => 'dave', password => 'beer' ] );
    ok $res->is_redirect, "POST /login with good username/password is_redirect";
    is $res->header('location'), 'http://localhost/',
      "... and redirect location is correct.";

    # check we can reach restricted page

    $res = get('/loggedin');
    ok $res->is_success, "GET /loggedin is_success now we're logged in";
    is $res->content, "You are logged in", "... and we can see page content.";

    # regex route

    $res = get('/regex/a');
    ok $res->is_success, "GET /regex/a is_success now we're logged in";
    is $res->content, "Matched", "... and we can see page content.";

    # cleanup
    get('/logout');

    # require_login should receive a coderef

    $trap->read;    # clear logs
    $res  = get('/require_login_no_sub');
    $logs = $trap->read;
    is @$logs, 1, "One message in the logs" or diag explain $logs;
    is $logs->[0]->{level}, 'warning', "We got a warning in the logs";
    is $logs->[0]->{message},
      'Invalid require_login usage, please see docs',
      "Warning message is as expected";
    $trap->read;    # clear logs

    $res  = get('/require_login_not_coderef');
    $logs = $trap->read;
    is @$logs, 1, "One message in the logs" or diag explain $logs;
    is $logs->[0]->{level}, 'warning', "We got a warning in the logs";
    is $logs->[0]->{message},
      'Invalid require_login usage, please see docs',
      "Warning message is as expected";
}

#------------------------------------------------------------------------------
#
#  roles
#
#------------------------------------------------------------------------------

sub _roles {

    # make sure we're not logged in

    {
        $trap->read;    # clear logs

        my $res = get('/loggedin');

        is( $res->code, 302, '[GET /loggedin] Correct code' )
          or diag explain $trap->read;

        is(
            $res->headers->header('Location'),
            'http://localhost/login?return_url=%2Floggedin',
            '/loggedin redirected to login page when not logged in'
        );
    }

    {
        $trap->read;
        my $res = get('/user_roles');
        is $res->code, 500,
          "user_roles with no logged_in_user and no args dies";
        my $logs = $trap->read;
        cmp_deeply $logs,
          superbagof(
            {
                formatted => ignore(),
                level     => 'error',
                message =>
                  re(qr/user_roles needs a username or a logged in user/),
            }
          ),
          "got error: user_roles needs a username or a logged in user",
          or diag explain $logs;
    }

    # and can't reach pages that have require_role

    {
        $trap->read;    # clear logs

        my $res = get('/beer');

        is( $res->code, 302, '[GET /beer] Correct code' )
          or diag explain $trap->read;

        is(
            $res->headers->header('Location'),
            'http://localhost/login?return_url=%2Fbeer',
            '/beer redirected to login page when not logged in'
        );
    }

    # ... and that we can log in with real details

    {
        $trap->read;    # clear logs

        my $res = post( '/login', [ username => 'dave', password => 'beer' ] );

        is( $res->code, 302, 'Login with real details succeeds' )
          or diag explain $trap->read;

        is get('/loggedin')->content, "You are logged in",
          "... and checking /loggedin route shows we are logged in";
    }

    # user_roles for logged_in_user

    {
        $trap->read;    # clear logs

        my $res = get('/roles');

        is( $res->code, 200, 'get /roles is 200' )
          or diag explain $trap->read;

        is( $res->content, 'BeerDrinker,Motorcyclist',
            'Correct roles for logged in user' );
    }

    # user_roles for specific user

    {
        $trap->read;    # clear logs

        my $res = get('/roles/bob');

        is( $res->code, 200, 'get /roles/bob is 200' )
          or diag explain $trap->read;

        is( $res->content, 'CiderDrinker',
            'Correct roles for other user in current realm' );
    }

    # Check we can request something which requires a role we have....

    {
        $trap->read;    # clear logs

        my $res = get('/beer');

        is( $res->code, 200,
            'We can request a route (/beer) requiring a role we have...' )
          or diag explain $trap->read;
    }

    # Check we can request a route that requires any of a list of roles,
    # one of which we have:

    {
        $trap->read;    # clear logs

        my $res = get('/anyrole');

        is( $res->code, 200,
            "We can request a multi-role route requiring with any one role" )
          or diag explain $trap->read;
    }

    {
        $trap->read;    # clear logs

        my $res = get('/allroles');

        is( $res->code, 200,
            "We can request a multi-role route with all roles required" )
          or diag explain $trap->read;
    }

    {
        $trap->read;    # clear logs

        my $res = get('/not_allroles');

        is( $res->code, 403, "/not_allroles response code 403" )
          or diag explain $trap->read;
        like $res->content, qr/Permission Denied/,
          "... and we got the Permission Denied page.";
    }

    {
        $trap->read;    # clear logs

        my $res = get('/piss/regex');

        is( $res->code, 200,
            "We can request a route requiring a regex role we have" )
          or diag explain $trap->read;
    }

    # ... but can't request something requiring a role we don't have

    {
        $trap->read;    # clear logs

        my $res = get('/piss');

        is( $res->code, 403,
            "route requiring a role we don't have gets response code 403" )
          or diag explain $trap->read;
        like $res->content, qr/Permission Denied/,
          "... and we got the Permission Denied page.";
    }

    # 2 arg user_has_role

    {
        $trap->read;    # clear logs

        my $res = get('/does_dave_drink_beer');
        is $res->code, 200, "/does_dave_drink_beer response is 200"
          or diag explain $trap->read;
        ok $res->content, "yup - dave drinks beer";
    }
    {
        $trap->read;    # clear logs

        my $res = get('/does_dave_drink_cider');
        is $res->code, 200, "/does_dave_drink_cider response is 200"
          or diag explain $trap->read;
        ok !$res->content, "no way does dave drink cider";
    }
    {
        $trap->read;    # clear logs

        my $res = get('/does_undef_drink_beer');
        is $res->code, 200, "/does_undef_drink_beer response is 200"
          or diag explain $trap->read;
        ok !$res->content, "undefined users cannot drink";
    }

    # Now, log out

    {
        $trap->read;    # clear logs

        my $res = get('/logout');

        is( $res->code, 302, 'Logging out returns 302' )
          or diag explain $trap->read;

        is( $res->headers->header('Location'),
            'http://localhost/',
            '/logout redirected to / (exit_page) after logging out' );
    }

    # Check we can't access protected pages now we logged out:

    {
        $trap->read;    # clear logs

        my $res = get('/loggedin');

        is( $res->code, 302, 'Status code on accessing /loggedin after logout' )
          or diag explain $trap->read;

        is(
            $res->headers->header('Location'),
            'http://localhost/login?return_url=%2Floggedin',
            '/loggedin redirected to login page after logging out'
        );
    }

    {
        $trap->read;    # clear logs

        my $res = get('/beer');

        is( $res->code, 302, 'Status code on accessing /beer after logout' )
          or diag explain $trap->read;

        is(
            $res->headers->header('Location'),
            'http://localhost/login?return_url=%2Fbeer',
            '/beer redirected to login page after logging out'
        );
    }

    # OK, log back in, this time as a user from the second realm

    {
        $trap->read;    # clear logs

        my $res =
          post( '/login', { username => 'burt', password => 'bacharach' } );

        is( $res->code, 302, 'Login as user from second realm succeeds' )
          or diag explain $trap->read;

        my $logs = $trap->read;
        cmp_deeply $logs,
          superbagof(
            {
                formatted => ignore(),
                level     => 'debug',
                message   => 'config2 accepted user burt'
            }
          ),
          "... and we see expected message in logs.";

        is get('/loggedin')->content, "You are logged in",
          "... and checking /loggedin route shows we are logged in";
    }

    # And that now we're logged in again, we can access protected pages

    {
        $trap->read;    # clear logs

        my $res = get('/loggedin');

        is( $res->code, 200, 'Can access /loggedin now we are logged in again' )
          or diag explain $trap->read;
    }

    {
        $trap->read;    # clear logs

        my $res = get('/roles/bob/config1');

        is( $res->code, 200, 'Status code on /roles/bob/config1 route.' )
          or diag explain $trap->read;

        is( $res->content, 'CiderDrinker',
            'Correct roles for other user in current realm' );
    }

    # Now, log out again

    {
        $trap->read;    # clear logs

        my $res = post('/logout');

        is( $res->code, 302, 'Logging out returns 302' )
          or diag explain $trap->read;

        is( $res->headers->header('Location'),
            'http://localhost/',
            '/logout redirected to / (exit_page) after logging out' );
    }

}

#------------------------------------------------------------------------------
#
#  update_current_user
#
#------------------------------------------------------------------------------

sub _update_current_user {

    # no user logged in

    $trap->read;
    my $res = get("/update_current_user");
    ok $res->is_success, "get /update_current_user is_success"
      or diag explain $trap->read;
    cmp_deeply $trap->read,
      superbagof(
        {
            formatted => ignore(),
            level     => 'debug',
            message =>
              'Could not update current user as no user currently logged in',
        }
      ),
      "Could not update current user as no user currently logged in";

    for my $realm (qw/config1 config2/) {

        # Now we're going to update the current user

        {
            $trap->read;    # clear logs

            # First login as the test user
            my $res = post(
                '/login',
                [
                    username => 'mark',
                    password => "wantscider",
                    realm    => $realm
                ]
            );

            is( $res->code, 302,
                "Login with real details succeeds (realm $realm)" );

            my $logs = $trap->read;
            cmp_deeply $logs,
              superbagof(
                {
                    formatted => ignore(),
                    level     => 'debug',
                    message   => "$realm accepted user mark"
                }
              ),
              "... and we see expected message in logs.";

            is get('/loggedin')->content, "You are logged in",
              "... and checking /loggedin route shows we are logged in";

            $trap->read;    # clear logs

            # Update the "current" user, that we logged in above
            $res = get("/update_current_user");
            is $res->code, 200, "get /update_current_user is 200"
              or diag explain $trap->read;

            $trap->read;    # clear logs

            # Check the update has worked
            $res = get("/get_user_mark/$realm");
            is $res->code, 200, "get /get_user_mark/$realm is 200"
              or diag explain $trap->read;

            my $user = YAML::Load $res->content;

            cmp_ok( $user->{name}, 'eq', "I love cider",
                "Name is now I love cider" );

            $trap->read;    # clear logs

            $res = post('/logout');
        }
    }
}

#------------------------------------------------------------------------------
#
#  update_user
#
#------------------------------------------------------------------------------

sub _update_user {

    # update_user with no realm specified

    $trap->read;
    my $res = post("/update_user", [ username => "mark", name => "FooBar" ]);
    is $res->code, 500, "update_user with no realm specified croaks 500";
    my $logs = $trap->read;
    cmp_deeply $logs,
      superbagof(
        {
            formatted => ignore(),
            level     => "error",
            message   => re(
                qr/Realm must be specified when more than one realm configured/
            ),
        }
      ),
      "got log: Realm must be specified when more than one realm configured."
      or diag explain $logs;

    for my $realm (qw/config1 config2/) {

        # First test a standard user details update.

        {
            $trap->read;    # clear logs

            # Get the current user settings, and make sure name is not what
            # we're going to change it to.
            my $res = get("/get_user_mark/$realm");
            is $res->code, 200, "get /get_user_mark/$realm is 200"
              or diag explain $trap->read;

            my $user = YAML::Load $res->content;
            my $name = $user->{name} || '';
            cmp_ok(
                $name, 'ne',
                "Wiltshire Apples $realm",
                "Name is not currently Wiltshire Apples $realm"
            );
        }
        {
            $trap->read;    # clear logs

            # Update the user
            my $res = get("/update_user_name/$realm");
            is $res->code, 200, "get /update_user_name/$realm is 200"
              or diag explain $trap->read;

            $trap->read;    # clear logs

            # check it
            $res = get("/get_user_mark/$realm");
            is $res->code, 200, "get /get_user_mark/$realm is 200"
              or diag explain $trap->read;

            my $user = YAML::Load $res->content;
            cmp_ok(
                $user->{name}, 'eq',
                "Wiltshire Apples $realm",
                "Name is now Wiltshire Apples $realm"
            );
        }

        # log in user dave and whilst logged in change user mark
        {
            my $res = post('/login', [username => 'dave', password => 'beer']);
            ok $res->is_redirect, "login user dave";

            $res = get('/logged_in_user');
            ok $res->is_success, "... and get logged_in_user is_success";
            like $res->content, qr/David Precious/,
              "... and we see dave's details."
              or diag $res->content;

            # Update mark
            $res = post(
                "/update_user",
                [
                    realm    => $realm,
                    username => "mark",
                    name     => "No beer for me"
                ]
            );
            ok $res->is_success, "change mark's name is success"
              or diag explain $trap->read;

            $trap->read;    # clear logs

            # check it
            $res = get("/get_user_mark/$realm");
            ok $res->is_success, "get /get_user_mark/$realm is_success"
              or diag explain $trap->read;

            my $user = YAML::Load $res->content;
            is $user->{name}, "No beer for me",
              "... and mark's name is now No beer for me.";

            $res = get('/logged_in_user');
            ok $res->is_success, "get logged_in_user is_success";
            like $res->content, qr/David Precious/,
              "... and we see still see dave's details."
              or diag $res->content;

        }
    }
}

#------------------------------------------------------------------------------
#
#  user_password
#
#------------------------------------------------------------------------------

sub _user_password {
    my $res;

    # user_password with valid username and password, no realm

    $trap->read;
    $res = post( '/user_password', [ username => 'dave', password => 'beer' ] );

    ok $res->is_success,
      "/user_password with valid username and password returns is_success"
      or diag explain $trap->read;
    is $res->content, 'dave', "... and it returned the username.";

    # user_password with valid username but bad password, no realm

    $trap->read;
    $res =
      post( '/user_password', [ username => 'dave', password => 'BadPW' ] );

    ok $res->is_success,
      "/user_password with valid username and password returns is_success"
      or diag explain $trap->read;
    ok !$res->content, "... and response is undef/empty.";

    # user_password with valid username and password and realm

    $trap->read;
    $res = post( '/user_password',
        [ username => 'dave', password => 'beer', realm => 'config1' ] );

    ok $res->is_success,
      "/user_password with valid username, password and realm is_success"
      or diag explain $trap->read;
    is $res->content, 'dave', "... and it returned the username.";

    # user_password with valid username and password but wrong realm

    $trap->read;
    $trap->read;
    $res = post( '/user_password',
        [ username => 'dave', password => 'beer', realm => 'config2' ] );

    ok $res->is_success,
      "/user_password with valid username, password but bad realm is_success"
      or diag explain $trap->read;
    ok !$res->content, "content shows fail";

    # now with logged_in_user

    $trap->read;
    $res = post( '/login', [ username => 'dave', password => 'beer' ] );

    is( $res->code, 302, 'Login with real details succeeds' )
      or diag explain $trap->read;

    is get('/loggedin')->content, "You are logged in",
      "... and checking /loggedin route shows we are logged in";

    # good password as only arg with logged in user

    $trap->read;
    $res = post( '/user_password', [ password => 'beer' ] );
    ok $res->is_success, "user_password password=beer is_success"
      or diag explain $trap->read;
    is $res->content, 'dave', "... and it returned the username.";

    # bad password as only arg with logged in user

    $trap->read;
    $res = post( '/user_password', [ password => 'cider' ] );
    ok $res->is_success, "user_password password=cider is_success"
      or diag explain $trap->read;
    ok !$res->content, "content shows fail";

    # logout

    $res = get('/logout');
    ok $res->is_redirect, "logout user dave is_redirect as expected";
    ok get('/loggedin')->is_redirect, 
      "... and checking /loggedin route shows dave is logged out.";

    # search for user by code that no user has yet

    my $code = 'UserPasswordResetCode123';
    $trap->read;
    $res = post( '/user_password', [ code => $code ] );
    ok $res->is_success, "user_password with code no user has is_success"
      or diag explain $trap->read;
    ok !$res->content, "content shows fail";

    # add code to dave's account details

    $trap->read;
    $res = post( '/update_user',
        [ username => 'dave', realm => 'config1', pw_reset_code => $code ] );
    ok $res->is_success,
      "Add password reset code to dave's account details is_success.";

    # now search for dave using code

    $trap->read;
    $res = post( '/user_password', [ code => $code ] );
    ok $res->is_success, "user_password with code no user has is_success"
      or diag explain $trap->read;
    is $res->content, 'dave', "... and user dave was found.";

    # change password

    $trap->read;
    $res = post( '/user_password',
        [ username => 'dave', new_password => 'paleale' ] );
    ok $res->is_success,
      "Update password without giving old password is_success";
    is $res->content, 'dave', "... and it returns the username."
      or diag explain $trap->read;
     
    # try login with old password

    $trap->read;
    $res = post( '/login', [ username => 'dave', password => 'beer' ] );

    ok $res->is_success, 'Login with old password fails with 200 OK code'
      or diag explain $res;

    ok get('/loggedin')->is_redirect,
      "... and checking /loggedin route shows we are NOT logged in.";

    # now new password

    $trap->read;
    $res = post( '/login', [ username => 'dave', password => 'paleale' ] );

    is( $res->code, 302, 'Login with real details succeeds' )
      or diag explain $trap->read;

    is get('/loggedin')->content, "You are logged in",
      "... and checking /loggedin route shows we are logged in";

    # logout

    $res = get('/logout');
    ok $res->is_redirect, "logout user dave is_redirect as expected";
    ok get('/loggedin')->is_redirect, 
      "... and checking /loggedin route shows dave is logged out.";


    # try to change password but supply bad old password

    $trap->read;
    $res = post( '/user_password',
        [ username => 'dave', password => 'bad', new_password => 'beer' ] );
    ok $res->is_success, "Update password with bad old password is_success";
    ok !$res->content, "... and it returns false."
      or diag explain $trap->read;
     
    # try to change password and supply good old password

    $trap->read;
    $res = post( '/user_password',
        [ username => 'dave', password => 'paleale', new_password => 'beer' ] );
    ok $res->is_success, "Update password with good old password is_success";
    is $res->content, 'dave', "... and user dave was found.";
     
    # try login with old password

    $trap->read;
    $res = post( '/login', [ username => 'dave', password => 'paleale' ] );

    ok $res->is_success, 'Login with old password fails with 200 OK code'
      or diag explain $res;

    ok get('/loggedin')->is_redirect,
      "... and checking /loggedin route shows we are NOT logged in.";

    # now new password

    $trap->read;
    $res = post( '/login', [ username => 'dave', password => 'beer' ] );

    is( $res->code, 302, 'Login with real details succeeds' )
      or diag explain $trap->read;

    is get('/loggedin')->content, "You are logged in",
      "... and checking /loggedin route shows we are logged in";

    # logout

    $res = get('/logout');
    ok $res->is_redirect, "logout user dave is_redirect as expected";
    ok get('/loggedin')->is_redirect, 
      "... and checking /loggedin route shows dave is logged out.";
}

1;
