#!perl

use strict;
use warnings;

use Test::More tests => 8;

use File::Spec;

use_ok( 'App::Module::Template', '_process_file' );

ok( my $rel_tmpl_path = File::Spec->catdir( File::Spec->curdir, 't', '.module-template', 'templates' ), 'set template path' );

ok( my $tmpl_file = File::Spec->catfile('t', '00-load.t' ), 'set template file' );

ok( my $rel_source_file = File::Spec->catfile( $rel_tmpl_path, $tmpl_file ), 'set source file path' );

is( _process_file($rel_tmpl_path, $rel_source_file), $tmpl_file, '_process_file returns stub' );

ok( my $tmpl_file2 = File::Spec->catfile( 'xt', 'author', 'critic.t' ), 'set template file' );

ok( my $rel_source_file2 = File::Spec->catfile( $rel_tmpl_path, $tmpl_file2 ), 'set source file path' );

is( _process_file($rel_tmpl_path, $rel_source_file2), $tmpl_file2, '_process_file returns stub' );
