#!perl

use strict;
use warnings;
no warnings 'redefine';

use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;
use File::Path;

BEGIN {
    skip_all => 'needs Catalyst::Plugin::Cache for testing'
        if not eval "use Catalyst::Plugin::Cache";
}

# This test that options can be passed to cache.

use Catalyst::Test 'TestApp';


#####
# These first few tests are really testing internal behaviour

ok( my $res = request('http://host1/cache/get_key'), 'request ok' );
is( $res->content, '/cache/get_key', 'key is just url for simple case' );

ok( $res = request('http://host1/cache/get_key?foo='.('x' x 200)), 'request ok' );
like $res->content, qr{/cache/get_key\?[0-9a-f]{40,40}$}i,
    'cache key has params encoded';

ok( $res = request('http://host1/cache/get_key/'.('x' x 200)), 'request ok' );
like $res->content, qr{/cache/get_key/x+[0-9a-f]{40,40}$}i,
    'cache key encodes long paths';

# reset the count for the following tests
ok( $res = request('http://host1/cache/set_count/0', 'request ok' ) );
is( $res->content, 0, 'count is reset' );

#
####

# add config option
# cannot call TestApp->config() because TestApp has already called setup
TestApp->config->{'Plugin::PageCache'}->{key_maker} = sub {
    my ($c) = @_;
    return $c->req->base . q{/} . $c->req->path;
};

# cache a page
ok( $res = request('http://host1/cache/count'), 'request ok' );
is( $res->content, 1, 'count is 1' );

# page will be served from cache
ok( $res = request('http://host1/cache/count'), 'request ok' );
is( $res->content, 1, 'count is still 1 from cache' );

# page will not be served from cache
ok( $res = request('http://host2/cache/count'), 'request ok' );
is( $res->content, 2, 'count is 2 from cache' );

# page will be served from cache
ok( $res = request('http://host2/cache/count'), 'request ok' );
is( $res->content, 2, 'count is still 2 from cache' );

done_testing();
