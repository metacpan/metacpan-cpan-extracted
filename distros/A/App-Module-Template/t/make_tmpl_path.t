#!perl

use strict;
use warnings;

use Test::More tests => 23;

use File::Path qw/remove_tree/;
use File::Spec;

use_ok( 'App::Module::Template::Initialize', '_make_tmpl_path' );

ok( my $tmpl_name = 'changes', 'set template name' );

ok( my $test_path = File::Spec->catdir( File::Spec->curdir, 'test_path' ), 'set test path' );

ok( my $result_path = File::Spec->catdir( $test_path, '.module-template', 'templates' ), 'set result path' );

SKIP: {
    skip( '$test_path exists', 1 ) unless -d $test_path;
    ok( remove_tree($test_path), 'remove test path' );
}

is( _make_tmpl_path(), undef, 'returns undef without args' );
is( _make_tmpl_path($test_path), undef, 'returns undef without tmpl name arg' );
is( _make_tmpl_path(undef, $tmpl_name), undef, 'returns undef without path arg' );
is( _make_tmpl_path($test_path, 'nothing'), undef, 'returns with invalid key name' );

is( _make_tmpl_path($test_path, $tmpl_name), $result_path, 'create template path returns path' );

ok( -d $result_path, 'result path exists' );

ok( remove_tree($result_path), 'removing result path' );

is( -d $result_path, undef, 'result path removed' );

# go deep

ok( my $tmpl_name2 = 'critic_test', 'set template name' );

ok( my $result_path2 = File::Spec->catdir( $test_path, '.module-template', 'templates', 'xt', 'author' ), 'set result path' );

is( _make_tmpl_path($test_path, $tmpl_name2), $result_path2, 'create template path returns path' );

is( _make_tmpl_path($test_path, $tmpl_name2), $result_path2, 'create template path again, returns path' );

ok( -d $result_path2, 'result path exists' );

ok( remove_tree($result_path2), 'removing result path' );

is( -d $result_path2, undef, 'result path removed' );

ok( -d $test_path, 'test path exists' );

ok( remove_tree($test_path), 'removing test path' );

is( -d $test_path, undef, 'test path removed' );
