use strict;
use warnings;
use Test::More import => ['!pass'];
use Dancer ':syntax';
use Dancer::Test;
use Redis;

my $default_server = $ENV{REDIS_SERVER} || '127.0.0.1:6379';

# check redis connection
my $redis_avail = eval { Redis->new(server => $default_server, debug => 0) };
plan skip_all => "Redis-server needs to be running on '$default_server' for tests" unless $redis_avail;

# complete settings
set redis_session => { server => $default_server, expire => 60 };
set session       => 'Redis';
set session_name  => 'mijNiaxDivOwsIbItMaf';

# sample application
load_app 't::lib::AppRedisSession';

my @samples = (
    '/'             => 'AppRedisSession',
    '/session/name' => 'mijNiaxDivOwsIbItMaf',
    '/names/clear'  => ';-)',
);

while (my($route, $content) = splice(@samples, 0, 2)) {
    my $resp = dancer_response GET => $route;
    is $resp->{status},  200,      "Response for GET $route is 200";
    is $resp->{content}, $content, "Response content for GET $route looks good";
}

my $values = [];
foreach (qw(Tom Dick Harry)) {
    push @$values, $_;
    my $route = '/names/set/' . $_;

    response_content_is         $route,      $_,      "Content for GET $route looks good";
    response_content_is_deeply '/names/get', $values, "Content for GET /names/get looks good after [$_]";
}

my $before = dancer_response GET => '/session/id';
is   $before->{status}, 200,                'Response code for GET /session/id is ok';
response_content_is  '/session/destroy', 1, 'Looks like old session session destroyed';

my $after  = dancer_response GET => '/session/id';

is   $after->{status},  200,                'Response code for GET /session/id is ok';
isnt $after->{content}, $before->{content}, 'New session created okay';

done_testing();
