use strict;
use warnings;

use Test::More tests => 12;
use Config::Any;
use Config::Any::Perl;

{
    my $file   = 't/conf/conf.pl';
    my $config = Config::Any::Perl->load( $file );

    ok( $config );
    is( $config->{ name }, 'TestApp' );

    my $config_load2 = Config::Any::Perl->load( $file );
    is_deeply( $config_load2, $config, 'multiple loads of the same file' );
}

# test invalid config
{
    my $file = 't/invalid/conf.pl';
    my $config;
    my $loaded = eval {
        $config = Config::Any::Perl->load( $file );
        1;
    };

    ok !$loaded, 'config load failed';
    is $config, undef, 'config load failed';
    like $@, qr/syntax error/, 'error thrown';
}

# parse error generated on invalid config
{
    my $file = 't/invalid/conf.pl';
    my $config;
    my $loaded = eval {
        $config = Config::Any::Perl->load( $file );
        Config::Any->load_files( { files => [$file], use_ext => 1} );
        1;
    };

    ok !$loaded, 'config load failed';
    is $config, undef, 'config load failed';
    like $@, qr/syntax error/, 'error thrown';
}

# test missing config
{
    my $file = 't/invalid/missing.pl';
    my $config;
    my $loaded = eval {
        $config = Config::Any::Perl->load( $file );
        1;
    };

    ok !$loaded, 'config load failed';
    is $config, undef, 'config load failed';
    isnt $@, '', 'error thrown';
}
