use strict;
use warnings;

use Test::More;
use Config::Any;
use Config::Any::INI;

if ( !Config::Any::INI->is_supported && !$ENV{RELEASE_TESTING} ) {
    plan skip_all => 'INI format not supported';
}
else {
    plan tests => 15;
}

{
    my $config = Config::Any::INI->load( 't/conf/conf.ini' );
    ok( $config, 'config loaded' );
    is( $config->{ name }, 'TestApp', "toplevel key lookup succeeded" );
    is( $config->{ Component }->{ 'Controller::Foo' }->{ foo },
        'bar', "nested hashref hack lookup succeeded" );
}

{
    my $config = Config::Any::INI->load( 't/conf/conf2.ini' );
    ok( $config, 'config loaded' );
    is( $config->{ name }, 'TestApp', "toplevel key lookup succeeded" );
    is( $config->{ 'Controller::Foo' }->{ foo },
        'bar', "nested hashref hack lookup succeeded" );
}

{
    local $Config::Any::INI::MAP_SECTION_SPACE_TO_NESTED_KEY = 0;
    my $config = Config::Any::INI->load( 't/conf/conf.ini' );
    ok( $config, 'config loaded (no-map-space mode)' );
    is( $config->{ name }, 'TestApp', "toplevel key lookup succeeded" );
    is( $config->{ 'Component Controller::Foo' }->{ foo },
        'bar', "unnested key lookup succeeded" );
}

{
    my $config = Config::Any::INI->load( 't/conf/subsections.ini' );

    my %expected
        = ( section1 =>
            { a => 1, subsection1 => { b => 2 }, subsection2 => { c => 3 } }
        );
    ok( $config, 'config loaded' );
    is_deeply( $config, \%expected, 'subsections parsed properly' );
}

# test invalid config
{
    my $file = 't/invalid/conf.ini';
    my $config = eval { Config::Any::INI->load( $file ) };

    is $config, undef, 'config load failed';
    isnt $@, '', 'error thrown';
}

# parse error generated on invalid config
{
    my $file = 't/invalid/conf.ini';
    my $config = eval { Config::Any->load_files( { files => [$file], use_ext => 1} ) };

    is $config, undef, 'config load failed';
    isnt $@, '', 'error thrown';
}
