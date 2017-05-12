#!perl

use strict;
use warnings;

use Test::More tests => 34;
use Test::Exception;

use File::Path qw/remove_tree make_path/;
use File::Spec;
use Template;

use_ok( 'App::Module::Template', '_process_dirs' );

ok( my $a1 = File::Spec->catdir( File::Spec->curdir, 't', '.module-template', 'templates' ), 'set template path' );

ok( my $abs_tmpl_path = File::Spec->rel2abs( $a1 ), 'set absolute template path' );

ok( my $a2 = File::Spec->catdir( File::Spec->curdir, 'test_dir' ), 'set output path' );

ok( my $abs_output_path = File::Spec->rel2abs( $a2 ), 'set absolute output path' );

ok( my $abs_tt2 = Template->new({ABSOLUTE => 1, OUTPUT_PATH => $abs_output_path}), 'create absolute TT2 object' );

ok( my $tmpl_vars = {}, 'set $tmpl_vars' );

ok( my $cant_read = File::Spec->catdir( File::Spec->curdir, 'cant_read' ), 'set cant_read' );

ok( make_path($cant_read), 'create cant_read' );

SKIP: {
    skip( 'Running under windows', 2 ) if $^O eq 'MSWin32';

    ok( chmod(oct(0400), $cant_read), 'make cant_read unreadable' );

    throws_ok{ _process_dirs($abs_tt2, $tmpl_vars, $abs_tmpl_path, $cant_read) } qr/\ACouldn't open directory/, '_process_dirs() fails on unreadable output path';
}

ok( remove_tree($cant_read), 'removing cant_read path' );

is( -d $cant_read, undef, 'cant_read path is removed' );

ok( _process_dirs($abs_tt2, $tmpl_vars, $abs_tmpl_path, $abs_tmpl_path), '_process_dirs() w/ absolute paths' );

ok( -d File::Spec->catdir( $abs_output_path, 'bin' ), 'bin exists' );
ok( -d File::Spec->catdir( $abs_output_path, 'lib' ), 'lib exists' );
ok( -d File::Spec->catdir( $abs_output_path, 't' ), 't exists' );
ok( -d File::Spec->catdir( $abs_output_path, 'xt' ), 'xt exists' );
ok( -d File::Spec->catdir( $abs_output_path, 'xt', 'author' ), 'xt/author exists' );
ok( -d File::Spec->catdir( $abs_output_path, 'xt', 'release' ), 'xt/release exists' );

ok( -f File::Spec->catfile( $abs_output_path, 'Changes' ), 'Changes exists' );
ok( -f File::Spec->catfile( $abs_output_path, 'LICENSE' ), 'LICENSE exists' );
ok( -f File::Spec->catfile( $abs_output_path, 'Makefile.PL' ), 'Makefile.PL exists' );
ok( -f File::Spec->catfile( $abs_output_path, 'README' ), 'README exists' );
ok( -f File::Spec->catfile( $abs_output_path, 'bin', 'script.pl' ), 'script.pl exists' );
ok( -f File::Spec->catfile( $abs_output_path, 'lib', 'Module.pm' ), 'Module.pm exists' );
ok( -f File::Spec->catfile( $abs_output_path, 't', '00-load.t' ), '00-load.t exists' );
ok( -f File::Spec->catfile( $abs_output_path, 'xt', 'author', 'pod-coverage.t' ), 'pod-coverage.t exists' );
ok( -f File::Spec->catfile( $abs_output_path, 'xt', 'author', 'critic.t' ), 'critic.t exists' );
ok( -f File::Spec->catfile( $abs_output_path, 'xt', 'author', 'perlcritic.rc' ), 'perlcritic.rc exists' );
ok( -f File::Spec->catfile( $abs_output_path, 'xt', 'release', 'pod-syntax.t' ), 'pod-syntax.t exists' );
ok( -f File::Spec->catfile( $abs_output_path, 'xt', 'release', 'kwalitee.t' ), 'kwalitee.t exists' );

ok( remove_tree($abs_output_path), 'removing output path' );

is( -d $abs_output_path, undef, 'output path is removed' );
