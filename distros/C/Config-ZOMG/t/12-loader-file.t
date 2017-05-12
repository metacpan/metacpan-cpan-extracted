use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Warn;

use Config::ZOMG;

sub has_Config_General {
    return eval "require Config::General;";
}

{
    my $config = Config::ZOMG->new(
        file => "t/assets/some_random_file.pl"
    );

    ok($config->load);
    is($config->load->{'Controller::Foo'}->{foo},       'bar');
    is($config->load->{'Model::Baz'}->{qux},            'xyzzy');
    is($config->load->{'view'},                         'View::TT');
    is($config->load->{'random'},                        1);
}

SKIP: {
    skip 'Config::General required' unless has_Config_General;
    my $config;

    $config = Config::ZOMG->new(
        path => "t/assets/order/../",
        name => "dotdot",
    );
    ok($config->load, 'Load a config from a directory path ending with ../');
    cmp_deeply( $config->load, {
        test => 'paths ending with ../',
    } );

    $config = Config::ZOMG->new(
        path => "t/assets/order/xyzzy.cnf"
    );
    cmp_deeply( $config->load, {
        cnf => 1,
        last => 'local_cnf',
        local_cnf => 1,
    } );

    $config = Config::ZOMG->new(
        file => "t/assets/order/xyzzy.cnf"
    );
    cmp_deeply( $config->load, {
        cnf => 1,
        last => 'cnf',
    } );

    $config = Config::ZOMG->new(
        path => "t/assets/order/xyzzy.cnf",
        no_local => 1
    );
    cmp_deeply( $config->load, {
        cnf => 1,
        last => 'cnf',
    } );

    warning_is { $config = Config::ZOMG->new( file => "t/assets/order/xyzzy.cnf", ) } undef;

    warning_is { $config = Config::ZOMG->new( file => "t/assets/order/xyzzy.cnf", no_06_warning => 1 ) } '';

    warning_is { $config = Config::ZOMG->new( file => "t/assets/order/xyzzy.cnf", quiet_deprecation => 1 ) } '';

    $config = Config::ZOMG->new(
        file => "t/assets/file-does-not-exist.cnf"
    );
    cmp_deeply( $config->load, {
    } );
}

done_testing;
