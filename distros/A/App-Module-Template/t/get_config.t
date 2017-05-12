#!perl

use strict;
use warnings;

use Test::More tests => 5;
use Test::Exception;

use File::Spec;

use_ok( 'App::Module::Template', '_get_config' );

ok( my $config_file = File::Spec->catfile( File::Spec->curdir, 't/.module-template/config' ), 'set config file' );

throws_ok{ _get_config() } qr/\ACould not read configuration file/, 'fails without config file';

ok( my $cfg = _get_config($config_file), 'get config file' );

is( ref $cfg, 'HASH', 'returns hash reference' );
