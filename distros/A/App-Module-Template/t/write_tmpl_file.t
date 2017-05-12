#!perl

use strict;
use warnings;

use Test::More tests => 16;
use Test::Exception;

use File::Path qw/remove_tree/;
use File::Spec;

use_ok( 'App::Module::Template::Initialize', '_write_tmpl_file', '_make_tmpl_path' );

ok( my $tmpl_name = 'changes', 'set template name' );

ok( my $test_path = File::Spec->catdir( File::Spec->curdir, 'test_path' ), 'set test path' );

ok( my $tmpl_path = File::Spec->catdir('.module-template', 'templates' ), 'set dir stub' );

SKIP: {
    skip( '$test_path exists', 1 ) unless -d $test_path;
    ok( remove_tree($test_path), 'remove test path' );
}

is( _write_tmpl_file(), undef, 'returns w/o args' );

is( _write_tmpl_file($test_path), undef, 'returns w/o template name' );

is( _write_tmpl_file(undef, $tmpl_name), undef, 'returns w/o base path' );

is( _write_tmpl_file($test_path, 'nothing'), undef, 'returns w/ invalid key' );

ok( my $fqfn = File::Spec->catfile( $test_path, $tmpl_path, 'Changes' ), 'set file name' );

throws_ok{ _write_tmpl_file($test_path, $tmpl_name) } qr/\ACouldn't open /, 'write template file fails on bad path';

ok( _make_tmpl_path($test_path, $tmpl_name), 'create template path' );

is( _write_tmpl_file($test_path, $tmpl_name), $fqfn, 'write template file' );

ok( -f $fqfn, 'file exists' );

ok( remove_tree($test_path), 'removing test path' );

is( -d $test_path, undef, 'test path removed' );
