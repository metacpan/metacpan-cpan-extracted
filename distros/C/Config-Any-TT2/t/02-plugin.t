use strict;
use warnings;

use Test::More;

eval "use Config::Any";
BAIL_OUT('Config::Any required for testing') if $@;

my $cfg_file = 't/conf/conf.tt2';

{
    my $cfg_hash = Config::Any->load_files(
        {
            files           => [$cfg_file],
            flatten_to_hash => 1,
            use_ext         => 1,
        }
    );
    my $config = $cfg_hash->{$cfg_file};
    ok($config, 'load_files');
    is( $config->{name}, 'TestApp',);
}

# test invalid config
{
    my $invalid_cfg_file = 't/invalid/conf.tt2';
    my $cfg_hash = eval {
        Config::Any->load_files(
            {
                files           => [$invalid_cfg_file],
                flatten_to_hash => 1,
                use_ext         => 1,
            }
        );
    };
    my $config = $cfg_hash->{$invalid_cfg_file};
    ok( !$config, 'config load failed' );
    ok( $@,       "error thrown ($@)" );
}

# test driver options
{
    my $cfg_hash = eval {
        Config::Any->load_files(
            {
                files           => [$cfg_file],
                flatten_to_hash => 1,
                use_ext         => 1,
                driver_args     => { TT2 => { STRICT => 0, }, }
            }
        );
    };
    my $config = $cfg_hash->{$cfg_file};
    ok($config, 'load_files with driver_args');
    is( $config->{name}, 'TestApp');
}

# test invalid driver options
{
    my $cfg_hash = eval {
        Config::Any->load_files(
            {
                files           => [$cfg_file],
                flatten_to_hash => 1,
                use_ext         => 1,
                driver_args     => { TT2 => { AUTO_RESET => 1}, }
            }
        );
    };
    my $config = $cfg_hash->{$cfg_file};
    ok( !$config, 'unsupported driver option' );
    ok( $@,       "error thrown ($@)" );
}

{
    my $cfg_hash = eval {
        Config::Any->load_files(
            {
                files           => [$cfg_file],
                flatten_to_hash => 1,
                use_ext         => 1,
                driver_args     => { TT2 => { INCLUDE_PATH => '/tmp'}, }
            }
        );
    };
    my $config = $cfg_hash->{$cfg_file};
    ok( !$config, 'wrong include path' );
    ok( $@,       "error thrown ($@)" );
}

done_testing();
