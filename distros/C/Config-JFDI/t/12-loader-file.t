use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

use Config::JFDI;
use t::Test;

sub has_Config_General {
    return eval "require Config::General;";
}

{
    my $config = Config::JFDI->new(
        file => "t/assets/some_random_file.pl"
    );

    ok($config->get);
    is($config->get->{'Controller::Foo'}->{foo},       'bar');
    is($config->get->{'Model::Baz'}->{qux},            'xyzzy');
    is($config->get->{'view'},                         'View::TT');
    is($config->get->{'random'},                        1);
    #is($config->get->{'foo_sub'},                      '__foo(x,y)__' );
    #is($config->get->{'literal_macro'},                '__literal(__DATA__)__');
}

SKIP: {
    skip 'Config::General required' unless has_Config_General;
    my $config;

    $config = Config::JFDI->new(
        path => "t/assets/order/../",
        name => "dotdot",
    );
    ok($config->load, 'Load a config from a directory path ending with ../');
    cmp_deeply( $config->get, {
        test => 'paths ending with ../',
    } );

    $config = Config::JFDI->new( 
        path => "t/assets/order/xyzzy.cnf"
    );
    cmp_deeply( $config->get, {
        cnf => 1,
        last => 'local_cnf',
        local_cnf => 1,
    } );

    $config = Config::JFDI->new(
        file => "t/assets/order/xyzzy.cnf"
    );
    cmp_deeply( $config->get, {
        cnf => 1,
        last => 'cnf',
    } );

    $config = Config::JFDI->new(
        path => "t/assets/order/xyzzy.cnf",
        no_local => 1
    );
    cmp_deeply( $config->get, {
        cnf => 1,
        last => 'cnf',
    } );

    warning_is { $config = Config::JFDI->new( file => "t/assets/order/xyzzy.cnf", ) } undef;

    warning_is { $config = Config::JFDI->new( file => "t/assets/order/xyzzy.cnf", no_06_warning => 1 ) } '';

    warning_is { $config = Config::JFDI->new( file => "t/assets/order/xyzzy.cnf", quiet_deprecation => 1 ) } '';

    $config = Config::JFDI->new(
        file => "t/assets/file-does-not-exist.cnf"
    );
    cmp_deeply( $config->get, {
    } );
}
