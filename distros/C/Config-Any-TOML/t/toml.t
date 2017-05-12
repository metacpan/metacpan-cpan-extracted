use strict;
use warnings;

use Test::More;
use Config::Any::TOML;

subtest 'TOML' => sub {
    if ( !Config::Any::TOML->is_supported ) {
        plan skip_all => 'TOML format not supported';
    }

    my $config = Config::Any::TOML->load('t/conf/conf.toml');
    ok($config);
    is( $config->{title}, 'TOML Example' );

    # test invalid config

    my $file = 't/invalid/conf.toml';
    $config = eval { Config::Any::TOML->load($file) };

    ok( !$config, 'config load failed' );
    ok( $@,       "error thrown ($@)" );

};

done_testing();

