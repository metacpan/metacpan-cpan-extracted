use strict;
use warnings;

use Test::More;
use lib qw(t/lib);
use DBICTest;
use Catalyst::Test 'CatTest';
use HTTP::Request::Common;

my $schema = DBICTest->init_schema();

BEGIN {
    eval "use DBD::SQLite";
    plan $@ ? (skip_all => 'needs DBD::SQLite for testing') : (tests => 12);
}

my $res;

# check for dbic
ok( $res = request('/action0'), 'request ok' );
is( $res->content, 'blog.woremacx.com', 'is dbic find error');

# check for C::P::FV::S works
ok( $res = request('/action1'), 'request ok' );
is( $res->content, 'name is blank', 'is NOT_BLANK error');
ok( $res = request('/action1?name=foo'), 'request ok' );
is( $res->content, 'url is blank', 'is NOT_BLANK error');
ok( $res = request('/action1?name=foo&url=http://example.com/'), 'request ok' );
is( $res->content, 'no errors', 'is has_error error');

# check for create_from_fvs
ok( $res = request('/action2?name=woremacx%20notes&url=http://blog.woremacx.com/notes/&no_such_column=1'), 'request ok' );
is( $res->content, 'woremacx notes', 'is create_from_fvs error');

# check for update_from_fvs
ok( $res = request('/action3?name=woremacx%20notes&url=http://blog.woremacx.com/notes/index.html&no_such_column=1'), 'request ok' );
is( $res->content, 'http://blog.woremacx.com/notes/index.html', 'is update_from_fvs error');

