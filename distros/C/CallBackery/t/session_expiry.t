use FindBin;
use lib $FindBin::Bin.'/../thirdparty/lib/perl5';
use lib $FindBin::Bin.'/../lib';
use lib $FindBin::Bin.'/lib';

use Mojo::Base -strict;
use Test::More;
use Test::Mojo;
use CallBackeryTest qw(setupTestConfig);
use Mojo::Transaction::HTTP;

setupTestConfig();

my $t = Test::Mojo->new('CallBackery');

# --- Task 1: sessionExpired defaults to false and is settable ---
{
    my $tx = Mojo::Transaction::HTTP->new;
    $tx->req->method('POST');
    my $c = CallBackery::Controller::RpcService->new(tx => $tx, app => $t->app);
    my $u = CallBackery::User->new(app => $t->app, controller => $c);
    is($u->sessionExpired, 0, 'sessionExpired defaults to 0');
    $u->sessionExpired(1);
    is($u->sessionExpired, 1, 'sessionExpired is settable');
}

# Mock user: control isUserAuthenticated / sessionExpired directly.
{
    package MockUser;
    use Mojo::Base -base;
    has authed  => 0;
    has expired => 0;
    sub isUserAuthenticated { shift->authed }
    sub sessionExpired      { shift->expired }
}

# Build an RpcService controller bound to a POST request, with a mock user and
# given rpc params. Returns the controller.
sub mk_ctrl {
    my (%arg) = @_;
    my $tx = Mojo::Transaction::HTTP->new;
    $tx->req->method('POST');
    my $c = CallBackery::Controller::RpcService->new(tx => $tx, app => $t->app);
    # Controller's tx attribute is weakened (Mojolicious::Controller); keep a
    # strong ref here so $tx isn't GC'd out from under $c once mk_ctrl returns.
    $c->{__test_tx} = $tx;
    $c->user(MockUser->new(authed => $arg{authed}, expired => $arg{expired}));
    $c->rpcParams($arg{params} // []);
    return $c;
}

# authenticated user -> access to an auth-required method is allowed
{
    my $c = mk_ctrl(authed => 1);
    is($c->allow_rpc_access('getSessionCookie'), 1, 'authenticated -> allowed');
}

# unauthenticated + expired, level-2 method -> dies code 7
{
    my $c = mk_ctrl(authed => 0, expired => 1);
    my $ok = eval { $c->allow_rpc_access('getSessionCookie'); 1 };
    ok(!$ok, 'expired level-2 dies');
    is($@->code, 7, 'expired -> code 7');
    like($@->message, qr/session/i, 'code 7 message mentions session');
}

# unauthenticated + NOT expired, level-2 method -> returns 0 (dispatcher -> code 6)
{
    my $c = mk_ctrl(authed => 0, expired => 0);
    is($c->allow_rpc_access('getSessionCookie'), 0, 'not-expired level-2 -> 0 (code 6)');
}

# unauthenticated + expired, level-3 method whose plugin instantiation dies ->
# code 7 (regression: must NOT escape as a generic code-9999 popup)
{
    my $c = mk_ctrl(authed => 0, expired => 1, params => ['NoSuchPlugin']);
    my $ok = eval { $c->allow_rpc_access('getPluginData'); 1 };
    ok(!$ok, 'expired level-3 dies despite plugin-instantiation failure');
    is($@->code, 7, 'expired level-3 -> code 7, not 9999');
}

# unauthenticated + NOT expired, level-3 non-anonymous plugin -> returns 0 (code 6)
{
    my $c = mk_ctrl(authed => 0, expired => 0, params => ['NoSuchPlugin']);
    is($c->allow_rpc_access('getPluginData'), 0, 'not-expired level-3 -> 0 (code 6)');
}

done_testing();
