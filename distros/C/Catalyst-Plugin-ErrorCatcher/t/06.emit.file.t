#!perl
# vim: ts=8 sts=4 et sw=4 sr sta
use strict;
use warnings;

BEGIN {
    use FindBin::libs;
}

use File::Find::Rule;
use File::Path;
use Test::More;

BEGIN {
    $ENV{ TESTAPP_CONFIG } = "$FindBin::Bin/lib/testapp-file.conf";
}

plan tests => 9;
use Catalyst::Test 'TestApp';

{
    eval "require Catalyst::Plugin::ErrorCatcher::File";
    is( $@, q{}, "no require errors" );

    # make a request
    ok( my ($res,$c) = ctx_request('http://localhost/foo/ok'), 'request ok' );
    # check the config
    is_deeply(
        $c->_errorcatcher_c_cfg->{'Plugin::ErrorCatcher::File'},
        {
            dir     => '/tmp/cpectest',
            prefix  => 'cpectest',
        },
        'file emitter config ok',
    );

    my $config = Catalyst::Plugin::ErrorCatcher::File::_check_config(
        $c, q{Dummy Output},
    );
    is( ref($config), q{HASH}, q{returned config is a hashref} );

    # check the prepared config
    is_deeply(
        $config,
        {
            dir     => '/tmp/cpectest',
            prefix  => 'cpectest',
        },
        'email emitter config ok',
    );
}

{
    my ($res, @files);

    open STDERR, '>/dev/null';
    mkdir q{/tmp/cpectest};

    # first request
    ok( $res = request('http://localhost/foo/not_ok'), 'request ok' );
    @files = File::Find::Rule
        ->file()
        ->in( '/tmp/cpectest' );
    is (@files, 1, q{one output file});

    # second request
    ok( $res = request('http://localhost/foo/not_ok'), 'request ok' );
    @files = File::Find::Rule
        ->file()
        ->in( '/tmp/cpectest' );
    is (@files, 2, q{two output files});

    # cleanup
    File::Path::rmtree('/tmp/cpectest');
}
