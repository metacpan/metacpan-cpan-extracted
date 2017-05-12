use Test::More;
use Test::Fatal;
use Plack::Test;
use HTTP::Request::Common;

BEGIN {
    $ENV{DANCER_CONFDIR} = 't/lib';
    $ENV{DANCER_ENVIRONMENT} = 'disable-roles';
}

like exception {
    package RequireAllRoles;
    use Dancer2;
    use Dancer2::Plugin::Auth::Extensible;

    get '/require_all_roles' => require_all_roles [qw(Foo Bar)] => sub {
        return 1;
    };
},
  qr/roles are disabled by disable_roles setting/,
  "App using require_all_roles dies during route setup";


like exception {
    package RequireAnyRole;
    use Dancer2;
    use Dancer2::Plugin::Auth::Extensible;

    get '/require_any_role' => require_any_role [qw(Foo Bar)] => sub {
        return 1;
    };
},
  qr/roles are disabled by disable_roles setting/,
  "App using require_any_role dies during route setup";

like exception {
    package RequireRole;
    use Dancer2;
    use Dancer2::Plugin::Auth::Extensible;

    get '/require_role' => require_role Foo => sub {
        return 1;
    };
},
  qr/roles are disabled by disable_roles setting/,
  "App using require_role dies during route setup";

{
    package TestApp;
    use Dancer2;
    use Dancer2::Plugin::Auth::Extensible;

    set logger => 'capture';
    set log => 'error';

    get '/user_has_role' => sub {
        user_has_role('Foo');
        return 1;
    };

    get '/user_roles' => sub {
        user_roles;
        return 1;
    };
}

my $app = TestApp->to_app;
is( ref $app, 'CODE', 'Got app' );

my $test = Plack::Test->create($app);
my $trap = TestApp->dancer_app->logger_engine->trapper;

my ($log, $res);

$res = $test->request(GET "/user_has_role");

ok !$res->is_success, "GET /user_has_role request does not return success";

is $res->code, 500, "... and the error code is 500";

$log = $trap->read->[0];
like $log->{message},qr/Cannot call user_has_role since roles are disabled/,
 "... and we have a log message saying that roles are disabled";

is $log->{level}, 'error', "... and the log level is error.";

$res = $test->request(GET "/user_roles");

ok !$res->is_success, "GET /user_roles request does not return success";

is $res->code, 500, "... and the error code is 500";

$log = $trap->read->[0];
like $log->{message},qr/Cannot call user_roles since roles are disabled/,
 "... and we have a log message saying that roles are disabled";

is $log->{level}, 'error', "... and the log level is error.";

done_testing;
