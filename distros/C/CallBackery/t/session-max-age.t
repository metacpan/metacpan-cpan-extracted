use FindBin;

use lib $FindBin::Bin.'/../thirdparty/lib/perl5';
use lib $FindBin::Bin.'/../lib';
use lib $FindBin::Bin.'/lib';

use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use CallBackeryTest qw(setupTestConfig);
use Mojo::Transaction::HTTP;
use Time::HiRes ();

setupTestConfig();

my $t = Test::Mojo->new('CallBackery');

no warnings qw(redefine once);
my @keep;
my $user = sub {
    my $tx = Mojo::Transaction::HTTP->new;
    $tx->req->headers->header('X-Session-Cookie' => shift);
    my $c = $t->app->build_controller($tx);
    push @keep, $tx, $c;
    return CallBackery::User->new(app => $t->app, controller => $c);
};
my $mint = sub {
    my $age = shift;
    local *CallBackery::User::gettimeofday = sub { Time::HiRes::time() - $age };
    return CallBackery::User->new(app => $t->app, userId => 1)->makeSessionCookie;
};

my $backend = $t->app->config->cfgHash->{BACKEND};
is $user->($mint->(30 * 24 * 60 * 60))->cookieConf->{u}, 1,
    'without max_session_age a month old session cookie is accepted';

$backend->{max_session_age} = 12 * 60 * 60;
my $fresh = $user->($mint->(0));
is $fresh->cookieConf->{u}, 1, 'a fresh session cookie is accepted';

my $old = $user->($mint->(24 * 60 * 60));
is $old->cookieConf->{u}, undef, 'a day old session cookie in the header is refused';
is $old->sessionExpired, 1, 'and reported as an expired session';

my $renewing = $user->($mint->(11 * 60 * 60));
$renewing->cookieConf;
my $renewed = $renewing->makeSessionCookie;
{
    local *CallBackery::User::gettimeofday = sub { Time::HiRes::time() + 2 * 60 * 60 };
    is $user->($renewed)->cookieConf->{u}, undef, 'renewing a cookie does not extend the session';
}

done_testing();
