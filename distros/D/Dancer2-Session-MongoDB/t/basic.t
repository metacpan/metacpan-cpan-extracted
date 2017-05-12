use strict;
use warnings;
use Test::More;

use JSON qw/from_json/;
use File::Temp 0.22;
use MongoDB;
use Safe::Isa;
use Plack::Test;
use HTTP::Cookies;
use HTTP::Request::Common;

my $db_name = "test_dancer_sessionfactory_mongodb";
my $engine  = "MongoDB";
my $tempdir = File::Temp::tempdir( CLEANUP => 1, TMPDIR => 1 );

{

    package App;
    use Dancer2;

    get '/no_session_data' => sub {
        return "session not modified";
    };

    get '/set_session/*' => sub {
        my ($name) = splat;
        session name => $name;
    };

    get '/read_session' => sub {
        my $name = session('name') || '';
        "name='$name'";
    };

    get '/change_session_id' => sub {
        if ( app->can('change_session_id') ) {
            app->change_session_id;
            return "supported";
        }
        else {
            return "unsupported";
        }
    };

    get '/destroy_session' => sub {
        my $name = session('name') || '';
        app->destroy_session;
        return "destroyed='$name'";
    };

    get '/churn_session' => sub {
        app->destroy_session;
        session name => 'damian';
        return "churned";
    };

    get '/list_sessions' => sub {
        return to_json( engine("session")->sessions );
    };

    get '/dump_session' => sub {
        return to_json( { %{ session() } } );
    };

    setting appdir => $tempdir;
    setting(
        engines => {
            session => {
                $engine => {
                    database_name => $db_name,
                }
            }
        }
    );
    setting( session => $engine );

    set(
        show_errors  => 1,
        startup_info => 0,
        environment  => 'production',
    );
}

my $url = "http://localhost";
my $test = Plack::Test->create( App->to_app );
my $jar = HTTP::Cookies->new;

# Skip tests if MongoDB isn't installed. If it is, 
# make sure we clean up from prior runs.
eval { 
    my $client = MongoDB->connect(); 
    my $db = $client->get_database($db_name);
    $db->drop;
};
plan skip_all => "No MongoDB on localhost" if $@;

my ( $req, $res );

# no session cookie set if session not referenced
$res = $test->request( GET "$url/no_session_data" );
ok $res->is_success, "/no_session_data is success" or diag explain $res;
$jar->extract_cookies($res);
ok !$jar->as_string, "no cookie set when session not referenced"
  or diag explain $res;

# still no session cookie if session read is attempted
$req = GET "$url/read_session";
$jar->add_cookie_header($req);
$res = $test->request($req);
ok $res->is_success, "/read_session is success";
$jar->extract_cookies($res);
ok !$jar->as_string, "no cookie set if empty session is read"
  or diag explain $res;

# set value into session and finally we get a session cookie
$req = GET "$url/set_session/larry";
$jar->add_cookie_header($req);
$res = $test->request($req);
ok $res->is_success, "/set_session/larry is success";
$jar->extract_cookies($res);
ok $jar->as_string, "cookie has been set";
like $jar->as_string, qr/Set-Cookie.*: dancer.session/i, "cookie looks good"
  or diag explain $jar->as_string;

$jar->as_string =~ /dancer\.session=(.+?);/;
my $sid1 = $1;

# read value back
$req = GET "$url/read_session";
$jar->add_cookie_header($req);
$res = $test->request($req);
ok $res->is_success, "/read_session is success";
$jar->extract_cookies($res);
ok $jar->as_string, "cookie has been set";
like $jar->as_string, qr/Set-Cookie.*: dancer.session/i, "cookie looks good"
  or diag explain $jar->as_string;
like $res->content, qr/name='larry'/, "session value looks good";

# session cookie should persist even if we don't touch sessions
$req = GET "$url/no_session_data";
$jar->add_cookie_header($req);
$res = $test->request($req);
ok $res->is_success, "/no_session_data is success";
$jar->extract_cookies($res);
ok $jar->as_string, "cookie has been set";
like $jar->as_string, qr/Set-Cookie.*: dancer.session/i, "cookie looks good"
  or diag explain $jar->as_string;

# change_session_id

$req = GET "$url/change_session_id";
$jar->add_cookie_header($req);
$res = $test->request($req);
ok $res->is_success, "/change_session_id is success";
$jar->extract_cookies($res);

$jar->as_string =~ /dancer\.session=(.+?);/;
my $sid2 = $1;

SKIP: {
    skip "change_session_id not supported by this version of Dancer2", 1
      if $res->content eq "unsupported";
    isnt $sid1, $sid2, "Session ID has been changed";
};

$req = GET "$url/read_session";
$jar->add_cookie_header($req);
$res = $test->request($req);
ok $res->is_success, "/read_session is success";
$jar->extract_cookies($res);
like $res->content, qr/name='larry'/, "session value looks good";

# destroy session and check that cookies are gone
$req = GET "$url/destroy_session";
$jar->add_cookie_header($req);
$res = $test->request($req);
ok $res->is_success, "/destroy_session is success";
$jar->extract_cookies($res);
ok !$jar->as_string, "session as been destroyed" or diag explain $res;


# shouldn't be sent session cookie after session destruction
$req = GET "$url/no_session_data";
$jar->add_cookie_header($req);
$res = $test->request($req);
ok $res->is_success, "/no_session_data is success";
$jar->extract_cookies($res);
ok !$jar->as_string, "no cookie set if empty session is read"
  or diag explain $res;

# set value into session again
$req = GET "$url/set_session/curly";
$jar->add_cookie_header($req);
$res = $test->request($req);
ok $res->is_success, "/set_session/curly is success";
$jar->extract_cookies($res);
ok $jar->as_string, "cookie has been set";
like $jar->as_string, qr/Set-Cookie.*: dancer.session/i, "cookie looks good"
  or diag explain $jar->as_string;

$jar->as_string =~ /dancer\.session=(.+?);/;
my $sid3 = $1;

isnt $sid3, $sid2, "New session has different ID";

# destroy and create a session in one request
$req = GET "$url/churn_session";
$jar->add_cookie_header($req);
$res = $test->request($req);
ok $res->is_success, "/churn_session is success";
$jar->extract_cookies($res);
ok $jar->as_string, "cookie has been set";

$jar->as_string =~ /dancer\.session=(.+?);/;
my $sid4 = $1;

isnt $sid4, $sid3, "Changed session has different ID";

# read value back
$req = GET "$url/read_session";
$jar->add_cookie_header($req);
$res = $test->request($req);
ok $res->is_success, "/read_session is success";
$jar->extract_cookies($res);
ok $jar->as_string, "cookie has been set";
like $res->content, qr/name='damian'/, "session value looks good";

# create separate session
$jar = HTTP::Cookies->new;
$req = GET "$url/set_session/moe";
$jar->add_cookie_header($req);
$res = $test->request($req);
ok $res->is_success, "/set_session/moe is success";
$jar->extract_cookies($res);
ok $jar->as_string, "cookie has been set";

# count sessions
$req = GET "$url/list_sessions";
$jar->add_cookie_header($req);
$res = $test->request($req);
ok $res->is_success, "/list_session is success";
$jar->extract_cookies($res);
my $list = from_json( $res->content );
is( scalar @$list, 2, "got correct number of sessions" );

$req = GET "$url/dump_session";
$jar->add_cookie_header($req);
$res = $test->request($req);
ok $res->is_success, "/dump_session is success";
my $dump = from_json( $res->content );

$jar->as_string =~ /dancer\.session=(.+?);/;
my $sid5 = $1;

is_deeply(
    $dump,
    {
        id       => $sid5,
        data     => { name => 'moe' },
        is_dirty => 0,
    },
    "session dump correct"
);

File::Temp::cleanup();


done_testing;

# vim: ts=4 sts=4 sw=4 et:
