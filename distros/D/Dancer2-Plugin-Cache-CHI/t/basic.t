use strict;
use warnings;
use Test::More tests => 25;
use Plack::Test;
use HTTP::Request::Common qw(GET PUT DELETE);

use lib 't';
use TestApp;
my $app = Dancer2->runner->psgi_app;
is ref $app, 'CODE', 'got app';

test_psgi $app, sub {
    my $cb  = shift;

    is $cb->(GET '/set/foo/bar')->code, 200, '/set/foo/bar';

    is $cb->(GET '/get/foo')->content, 'bar', '/get/foo';

    is $cb->(GET '/cached')->content, 1, '/cached';

    is $cb->(GET '/cached')->content, 2, '/cached (not cached yet)';

    is $cb->(GET '/check_page_cache')->code, 200, '/check_page_cache';

    is $cb->(GET '/counter')->content, 2, 'counter is at 2';
    is $cb->(GET '/cached')->content, 2, '/cached (cached!)';
    is $cb->(GET '/counter')->content, 2, q{counter didn't move};

    is $cb->(GET '/clear')->code, 200, '/clear';

    is $cb->(GET '/cached')->content, 3, '/cached (cleared)';

    my $secret = 'flamingo';
    is $cb->(PUT '/stash', Content => $secret)->code, 200, 'secret stashed';

    is $cb->(GET '/stash')->content, $secret, 'secret retrieved';
    is $cb->(DELETE '/stash')->code, 200, 'secret removed';
    is $cb->(GET '/stash')->content, '', 'secret gone';

    is $cb->(GET '/compute')->content, 'aab', '/compute, first';
    is $cb->(GET '/compute')->content, 'aab', '/compute, cached';
    is $cb->(GET '/clear')->code, 200, '/clear cache';
    is $cb->(GET '/compute')->content, 'aac', '/compute, again';

    is $cb->(GET '/expire_quick')->content, 1;
    is $cb->(GET '/expire_quick')->content, 1;

    subtest 'expires in 2 seconds' => sub {
        plan tests => 1;

        for ( 1..10 ) {
            sleep 1;
            my $resp = $cb->(GET '/expire_quick');
            return pass "expired in $_ seconds" if $resp->content == 2;
        }

        fail "didn't expire in 10 seconds";
    };

    is $cb->(GET '/clear_headers')->code, 200;
    is $cb->(GET '/headers')->header('X-Foo'), 1;
    is $cb->(GET '/headers')->header('X-Foo'), 1;
};
