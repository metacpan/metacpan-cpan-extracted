#!perl

use strict;
use warnings;

use Test::More tests => 9;
use File::Spec;

use_ok( 'App::Module::Template', '_process_file' );

ok( my $atp = File::Spec->catdir( File::Spec->curdir, 't', '.module-template', 'templates' ), 'set template path'
);

ok( my $abs_tmpl_path = File::Spec->rel2abs( $atp ), 'set absolute template path' );

ok( my $tmpl_file = File::Spec->catfile('t', '00-load.t' ), 'set template file' );

ok( my $abs_source_file = File::Spec->catfile( $abs_tmpl_path, $tmpl_file ), 'set source file path' );

is( _process_file($abs_tmpl_path, $abs_source_file), $tmpl_file, '_process_file returns stub' );

ok( my $tmpl_file2 = File::Spec->catfile('xt', 'author', 'critic.t' ), 'set template file' );

ok( my $abs_source_file2 = File::Spec->catfile( $abs_tmpl_path, $tmpl_file2 ), 'set source file path' );

is( _process_file($abs_tmpl_path, $abs_source_file2), $tmpl_file2, '_process_file returns stub' );
