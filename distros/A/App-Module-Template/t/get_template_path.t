#!perl

use strict;
use warnings;

use Test::More tests => 8;
use Test::Exception;

use File::HomeDir;
use File::Path qw/remove_tree make_path/;
use File::Spec;

use_ok( 'App::Module::Template', '_get_template_path' );

ok( my $path = File::Spec->catdir( File::Spec->curdir, 'test_dir' ), 'set path' );

throws_ok{ _get_template_path($path) } qr/\ATemplate directory/, 'fails for non-existent template path';

ok( make_path($path), 'create template path' );

ok( -d $path, 'template path exists' );

is( _get_template_path($path), $path, 'returns path' );

ok( remove_tree($path), 'removing path' );

is( -d $path, undef, 'path removed' );
