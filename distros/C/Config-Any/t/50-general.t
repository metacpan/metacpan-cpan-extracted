use strict;
use warnings;

use Test::More;
use Config::Any;
use Config::Any::General;

if ( !Config::Any::General->is_supported && !$ENV{RELEASE_TESTING}) {
    plan skip_all => 'Config::General format not supported';
}
else {
    plan tests => 9;
}

{
    my $config = Config::Any::General->load( 't/conf/conf.conf' );
    ok( $config );
    is( $config->{ name }, 'TestApp' );
    ok( exists $config->{ Component } );
}

{
    my $config = Config::Any::General->load( 't/conf/conf.conf',
        { -LowerCaseNames => 1 } );
    ok( exists $config->{ component } );
}

{
    my $config
        = Config::Any::General->load( 't/conf/single_element_arrayref.conf' );
    is_deeply $config->{ foo }, [ 'bar' ], 'single element arrayref';
}

# test invalid config
{
    my $file = 't/invalid/conf.conf';
    my $config = eval { Config::Any::General->load( $file ) };

    is $config, undef, 'config load failed';
    isnt $@, '', 'error thrown';
}

# parse error generated on invalid config
{
    my $file = 't/invalid/conf.conf';
    my $config = eval { Config::Any->load_files( { files => [$file], use_ext => 1} ) };

    is $config, undef, 'config load failed';
    isnt $@, '', 'error thrown';
}
