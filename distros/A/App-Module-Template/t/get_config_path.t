#!perl

use strict;
use warnings;

use Test::More tests => 7;
use Test::Exception;

use File::Spec;

use_ok( 'App::Module::Template', '_get_config_path' );

ok( my $template_dir = File::Spec->catdir( File::Spec->curdir, 't', '.module-template', 'templates' ), 'set template dir' );

ok( my $config_file = File::Spec->catfile( File::Spec->curdir, 't', '.module-template', 'config' ), 'set config file' );

throws_ok{ _get_config_path(undef, 'some') } qr/\ACould not locate configuration file/, 'fails for non-existent file';

is( _get_config_path($config_file), $config_file, 'returns config file' );

ok( my $ret_config = File::Spec->catfile( File::Spec->curdir, 't', '.module-template', 'templates', '..', 'config' ), 'set return config' );

is( _get_config_path(undef, $template_dir), $ret_config, 'returns config file' );
