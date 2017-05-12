#!perl

use t::ests;
use HTTP::Cookies;

my $jar = HTTP::Cookies->new;
my $redis = redis;

{

    package Webservice;
    use Dancer2;
    use Dancer2::Plugin::Shutdown::Redis;
    
    shutdown_redis($redis, 'shutdown');
    
    get '/start' => sub {
        shift->destroy_session;
        my $id = session->id;
        session(started => time);
        return $id;
    };
    
    get '/status' => sub {
        my $app = shift;
        my $id = Dancer2::Plugin::Shutdown::Redis::has_valid_session($app);
        return Dancer2::Plugin::Shutdown::Redis::session_status($app) unless $id;
        my $time = session('started') // 'X';
        $time = time - $time if $time ne 'X';
        return "$id#$time";
    };

}

my $PT = init('Webservice');

plan tests => 15;

my $sessid;

subtest 'status on first time' => sub {
    plan tests => 2;
    my $R = $PT->request( GET('http://localhost/status') );
    is $R->code => 200, "http status code";
    is $R->content => 'missing', "cookie status"
};

subtest 'create new session' => sub {
    plan tests => 1;
    my $now = time;
    my $R = $PT->request( GET('http://localhost/start') );
    is $R->code => 200, "http status code";
    $sessid = $R->content;
    $jar->extract_cookies($R);
};

subtest 'status of new session' => sub {
    plan tests => 3;
    my $Q = GET('http://localhost/status');
    $jar->add_cookie_header($Q);
    my $R = $PT->request($Q);
    is $R->code => 200, "http status code";
    my $rx = qr{^(.+)#(\d+|X)$}s;
    like $R->content => $rx, "response body";
    $R->content =~ $rx;
    is $1 => $sessid, "session id";
    $jar->extract_cookies($R);
};

is $jar->{COOKIES}->{'localhost.local'}->{'/'}->{'dancer.session'}->[5] => undef, 'session cookie never expires';

is redis_hget($redis, 'shutdown', 'state') => undef, "state not set yet";
is redis_hget($redis, 'shutdown', 'final') => undef, "final not set yet";

ok redis_hset($redis, 'shutdown', 'state', 1), "set state to 1";
ok redis_hset($redis, 'shutdown', 'final', time + 1), "set final to now+1s";

    is redis_hget($redis, 'shutdown', 'state') => 1, 'state is 1';
cmp_ok redis_hget($redis, 'shutdown', 'final'), '>', time, 'final is in future';

subtest 'status without valid session' => sub {
    plan tests => 1;
    my $R = $PT->request( GET('http://localhost/status') );
    is $R->code => 503, "http status code";
};

subtest 'status with valid session' => sub {
    plan tests => 2;
    my $Q = GET('http://localhost/status');
    $jar->add_cookie_header($Q);
    my $R = $PT->request($Q);
    like $R->header('Warning') => qr{^199 Application shuts down in \d+ seconds$}, "http warning header";
    is $R->code => 200, "http status code";
    $jar->extract_cookies($R);
};

cmp_ok $jar->{COOKIES}->{'localhost.local'}->{'/'}->{'dancer.session'}->[5], '>', time   , "session cookies expires in future";
cmp_ok $jar->{COOKIES}->{'localhost.local'}->{'/'}->{'dancer.session'}->[5], '<', time+10, "session cookies expires in less than 10 seconds";

note "sleeping some seconds";
sleep 2;

subtest 'status with valid session again' => sub {
    plan tests => 1;
    my $Q = GET('http://localhost/status');
    $jar->add_cookie_header($Q);
    my $R = $PT->request($Q);
    is $R->code => 503, "http status code";
};

done_testing;
