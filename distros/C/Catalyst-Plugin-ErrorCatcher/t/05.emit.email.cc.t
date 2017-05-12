#!perl
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

BEGIN {
    use FindBin::libs;
}

use Test::More;
use Sys::Hostname;

BEGIN {
    $ENV{ TESTAPP_CONFIG } = "$FindBin::Bin/lib/testapp-cc.conf";
}

plan tests => 11;
use Catalyst::Test 'TestApp';

{
    eval "require Catalyst::Plugin::ErrorCatcher::Email";
    is( $@, q{}, "no require errors" );

    # make a request
    ok( my ($res,$c) = ctx_request('http://localhost/foo/ok'), 'request ok' );
    # check the config
    is_deeply(
        $c->_errorcatcher_c_cfg->{'Plugin::ErrorCatcher::Email'},
        {
            to => 'address@example.com',
            from => 'another@example.com',
            subject => 'Alternative Subject Line',
            cc => 'copy@example.com',
        },
        'email emitter config ok',
    );

    my $config = Catalyst::Plugin::ErrorCatcher::Email::_check_config(
        $c, q{Dummy Output},
    );
    is( ref($config), q{HASH}, q{returned config is a hashref} );

    # check the prepared config
    is_deeply(
        $config,
        {
            to => 'address@example.com',
            from => 'another@example.com',
            subject => 'Alternative Subject Line',
            cc => 'copy@example.com',
        },
        'email emitter config ok',
    );
}

# test a request where the config doesn't have (because we remove it) a cc
# value
{
    eval "require Catalyst::Plugin::ErrorCatcher::Email";
    is( $@, q{}, "no require errors" );

    # make a request
    ok( my ($res,$c) = ctx_request('http://localhost/foo/ok'), 'request ok' );
    # check the config
    is_deeply(
        $c->_errorcatcher_c_cfg->{'Plugin::ErrorCatcher::Email'},
        {
            to => 'address@example.com',
            from => 'another@example.com',
            subject => 'Alternative Subject Line',
            cc => 'copy@example.com',
        },
        'email emitter config ok',
    );
    # delete the cc option for the module
    delete $c->_errorcatcher_c_cfg->{'Plugin::ErrorCatcher::Email'}{cc},
    is_deeply(
        $c->_errorcatcher_c_cfg->{'Plugin::ErrorCatcher::Email'},
        {
            to => 'address@example.com',
            from => 'another@example.com',
            subject => 'Alternative Subject Line',
        },
        'email emitter config ok after cc removal',
    );

    my $config = Catalyst::Plugin::ErrorCatcher::Email::_check_config(
        $c, q{Dummy Output},
    );
    is( ref($config), q{HASH}, q{returned config is a hashref} );

    # check the prepared config
    is_deeply(
        $config,
        {
            to => 'address@example.com',
            from => 'another@example.com',
            subject => 'Alternative Subject Line',
        },
        'email emitter config ok',
    );
}

