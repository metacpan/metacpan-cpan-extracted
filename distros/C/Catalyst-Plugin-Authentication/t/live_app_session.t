use strict;
use warnings;

use Test::More;

BEGIN {
    eval {
      require Catalyst::Plugin::Session;
      require Catalyst::Plugin::Session::State::Cookie;
    } or do {
      plan skip_all => "This test needs Catalyst::Plugin::Session and Catalyst::Plugin::Session::State::Cookie installed";
    }
}

use lib 't/lib';
use Catalyst::Test qw/AuthSessionTestApp/;
use HTTP::Cookies;
use HTTP::Request::Common qw(GET);

my $jar = HTTP::Cookies->new;
sub _request {
    my $url = shift;
    $url =~ s{^/}{http://localhost/};
    my $req = GET $url;
    $jar->add_cookie_header($req);
    my $res = request($req);
    $jar->extract_cookies($res);
    return $res;
}

my $res;

$res = _request('/moose');
ok +$res->is_success, 'get ok';

$res = _request('/elk');
ok +$res->is_success, 'get ok';

$res = _request('/yak');
ok !$res->is_success, 'Not ok, user unable to be resotred == nasal demons';

foreach my $type (qw/ goat fluffy_bunny possum butterfly /) {
    $res = _request("/$type");
    ok +$res->is_success, "get $type ok";
}

done_testing;
