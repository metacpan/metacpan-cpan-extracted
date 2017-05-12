use strict;
use warnings;

use Test::More;
use Config::Any;
use Config::Any::XML;

if ( !Config::Any::XML->is_supported && !$ENV{RELEASE_TESTING} ) {
    plan skip_all => 'XML format not supported';
}
else {
    plan tests => 7;
}

{
    my $config = Config::Any::XML->load( 't/conf/conf.xml' );
    is_deeply $config, {
        'Component' => {
            'Controller::Foo' => {
                'foo' => 'bar'
            },
        },
        'name' => 'TestApp',
        'Model' => {
            'Model::Baz' => {
                'qux' => 'xyzzy',
            },
        },
    }, 'config loaded';
}

# test invalid config
SKIP: {
    my $broken_libxml
        = eval { require XML::LibXML; XML::LibXML->VERSION lt '1.59'; };
    skip 'XML::LibXML < 1.58 has issues', 2 if $broken_libxml;

    local $SIG{ __WARN__ } = sub { };    # squash warnings from XML::Simple
    my $file = 't/invalid/conf.xml';
    my $config = eval { Config::Any::XML->load( $file ) };

    is $config, undef, 'config load failed';
    isnt $@, '', 'error thrown';
}

# test conf file with array ref
{
    my $file = 't/conf/conf_arrayref.xml';
    my $config = eval { Config::Any::XML->load( $file ) };

    is_deeply $config, {
        'indicator' => 'submit',
        'elements' => [
            {
                'label' => 'Label1',
                'type' => 'Text',
            },
            {
                'label' => 'Label2',
                'type' => 'Text',
            },
        ],
    }, 'config loaded';
    is $@, '', 'no error thrown';
}

# parse error generated on invalid config
{
    my $file = 't/invalid/conf.xml';
    my $config = eval { Config::Any->load_files( { files => [$file], use_ext => 1} ) };

    is $config, undef, 'config load failed';
    isnt $@, '', 'error thrown';
}

