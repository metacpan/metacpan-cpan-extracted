use strict;
use warnings;

use lib 't';

use Test::More;

use TestApp;

use Dancer::Test apps => [ 'TestApp' ];

plan tests => 24;

response_status_is [ 'GET', '/set/foo/bar' ], 200, '/set/foo/bar';

response_content_is [ 'GET', '/get/foo' ], 'bar', '/get/foo';

response_content_is [ 'GET', '/cached' ], 1, '/cached';

response_content_is [ 'GET', '/cached' ], 2, '/cached (not cached yet)';

response_status_is [ 'GET', '/check_page_cache' ], 200, '/check_page_cache';

response_content_is [ 'GET', '/counter' ], 2, 'counter is at 2';
response_content_is [ 'GET', '/cached' ], 2, '/cached (cached!)';
response_content_is [ 'GET', '/counter' ], 2, q{counter didn't move};

response_status_is [ 'GET', '/clear' ], 200, '/clear';

response_content_is [ 'GET', '/cached' ], 3, '/cached (cleared)';

my $secret = 'flamingo';
my $resp = dancer_response PUT => '/stash', { body => $secret };

is $resp->status => 200, 'secret stashed';

response_content_is [ GET => '/stash' ], $secret, 'secret retrieved';
response_status_is [ DELETE => '/stash' ], 200, 'secret removed';
response_content_is [ GET => '/stash' ], '', 'secret gone';

response_content_is [ GET => '/compute' ], 'aab', '/compute, first';
response_content_is [ GET => '/compute' ], 'aab', '/compute, cached';
response_status_is [ GET => '/clear' ], 200, '/clear cache';
response_content_is [ GET => '/compute' ], 'aac', '/compute, again';

response_content_is '/expire_quick' => 1;
response_content_is '/expire_quick' => 1;

subtest 'expires in 2 seconds' => sub {
    plan tests => 1;

    for ( 1..10 ) {
        sleep 1;
        my $resp = dancer_response GET => '/expire_quick';
        return pass "expired in $_ seconds" if $resp->content == 2;
    }

    fail "didn't expire in 10 seconds";
};

response_status_is '/clear_headers' => 200;
response_headers_include [ GET => '/headers' ], [ 'X-Foo' => 1 ];
response_headers_include [ GET => '/headers' ], [ 'X-Foo' => 1 ];
