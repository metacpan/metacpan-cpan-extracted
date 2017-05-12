#!perl
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

BEGIN {
    use FindBin::libs;
}

use Test::More;

BEGIN {
    $ENV{ TESTAPP_CONFIG } = "$FindBin::Bin/lib/testapp.conf";
}

plan tests => 5;
use Catalyst::Test 'TestApp';

{
    ok( my ($res,$c) = ctx_request('http://localhost/foo/ok'), 'request ok' );

    # make sure we have expected values in the config
    is(
        $c->_errorcatcher_cfg->{emit_module},
        q{Catalyst::Plugin::ErrorCatcher::Email},
        q{emit_module ok in config}
    );
    is(
        $c->_errorcatcher_cfg->{context},
        4,
        q{context ok in config}
    );
    is(
        $c->_errorcatcher_cfg->{verbose},
        0,
        q{verbose ok in config}
    );

    is_deeply(
        $c->_errorcatcher_c_cfg->{'Plugin::ErrorCatcher::Email'},
        {
            to => 'address@example.com',
            from => 'another@example.com',
            subject => 'Alternative Subject Line',
        },
        'email emitter config ok',
    );
}
