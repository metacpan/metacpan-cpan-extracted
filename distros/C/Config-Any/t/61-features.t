package MockApp;
use strict;
use warnings;

$|++;

use Test::More tests => 14;
use Scalar::Util qw(blessed reftype);

use Config::Any;
use Config::Any::INI;

our $cfg_file = 't/conf/conf.foo';

eval { Config::Any::INI->load( $cfg_file ); };

SKIP: {
    skip "File loading backend for INI not found", 14 if $@;

    my $struct;    # used to make sure parsing works for arrays and hashes

    # force_plugins
    {
        my $result = Config::Any->load_files(
            {   files         => [ $cfg_file ],
                force_plugins => [ qw(Config::Any::INI) ]
            }
        );

        ok( $result, 'load file with parser forced' );

        ok( my $first = $result->[ 0 ], 'load_files returns an arrayref' );
        ok( ref $first, 'load_files arrayref contains a ref' );

        my $ref = blessed $first ? reftype $first : ref $first;
        is( substr( $ref, 0, 4 ), 'HASH', 'hashref' );

        $struct = $first;

        my ( $name, $cfg ) = %$first;
        is( $name, $cfg_file, 'filenames match' );

        my $cfgref = blessed $cfg ? reftype $cfg : ref $cfg;
        is( substr( $cfgref, 0, 4 ), 'HASH', 'hashref cfg' );

        is( $cfg->{ name }, 'TestApp', 'appname parses' );
        is( $cfg->{ Component }{ "Controller::Foo" }->{ foo },
            'bar', 'component->cntrlr->foo = bar' );
        is( $cfg->{ Model }{ "Model::Baz" }->{ qux },
            'xyzzy', 'model->model::baz->qux = xyzzy' );
    }

    # flatten_to_hash
    {
        my $result = Config::Any->load_files(
            {   files           => [ $cfg_file ],
                force_plugins   => [ qw(Config::Any::INI) ],
                flatten_to_hash => 1
            }
        );

        ok( $result,     'load file with parser forced, flatten to hash' );
        ok( ref $result, 'load_files hashref contains a ref' );

        my $ref = blessed $result ? reftype $result : ref $result;
        is( substr( $ref, 0, 4 ), 'HASH', 'hashref' );

        is_deeply( $result, $struct,
            'load_files return an hashref (flatten_to_hash)' );
    }

    # use_ext
    {
        ok( my $result = Config::Any->load_files(
                {   files         => [ $cfg_file ],
                    force_plugins => [ qw(Config::Any::INI) ],
                    use_ext       => 1
                }
            ),
            "load file with parser forced"
        );
    }
}

