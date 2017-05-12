#!perl

use strict;
use warnings;

use Test::More tests => 30;
use Test::Exception;

use File::HomeDir;
use File::Path qw/remove_tree/;
use File::Spec;

ok( @ARGV = ( '-m', 'Some::Test' ), 'set @ARGV' );

use_ok( 'App::Module::Template', 'run' );

ok( my $module_dir = File::Spec->catdir( File::Spec->curdir, 'Some-Test' ), 'set module directory' );

ok( my $mt_dir = File::Spec->catdir( File::HomeDir->my_home(), '.module-template' ), 'set module-template dir' );

# make sure we have a clean environment
SKIP: {
    skip( 'module directory does not exist', 1 ) unless -d $module_dir;

    ok(remove_tree($module_dir), 'removing previous test dir' );
}

# don't clobber an existing .module-template directory
SKIP: {
    skip( "$mt_dir exists", 23) if -d $mt_dir;

    ok( run(@ARGV), 'run() w/ module name and no template dir' );

    ok( -d $mt_dir, '.module-template created in home' );

    ok( my $tmpl_dir = File::Spec->catdir( $mt_dir, 'templates' ), 'set template dir' );

    ok( -f File::Spec->catfile( $mt_dir, 'config' ), 'config exists' );
    ok( -f File::Spec->catfile( $tmpl_dir, '.gitignore' ), '.gitignore exists' );
    ok( -f File::Spec->catfile( $tmpl_dir, '.travis.yml' ), '.travis.yml exists' );
    ok( -f File::Spec->catfile( $tmpl_dir, 'Changes' ), 'Changes exists' );
    ok( -f File::Spec->catfile( $tmpl_dir, 'LICENSE' ), 'LICENSE exists' );
    ok( -f File::Spec->catfile( $tmpl_dir, 'Makefile.PL' ), 'Makefile.PL exists' );
    ok( -f File::Spec->catfile( $tmpl_dir, 'README' ), 'README exists' );
    ok( -f File::Spec->catfile( $tmpl_dir, 'bin', 'script.pl' ), 'script.pl exists' );
    ok( -f File::Spec->catfile( $tmpl_dir, 'lib', 'Module.pm' ), 'Module.pm exists' );
    ok( -f File::Spec->catfile( $tmpl_dir, 't', '00-load.t' ), '00-load.t exists' );
    ok( -f File::Spec->catfile( $tmpl_dir, 'xt', 'author', 'critic.t' ), 'critic.t exists' );
    ok( -f File::Spec->catfile( $tmpl_dir, 'xt', 'author', 'perlcritic.rc' ), 'perlcritic.rc exists' );
    ok( -f File::Spec->catfile( $tmpl_dir, 'xt', 'author', 'pod-coverage.t' ), 'pod-coverage.t exists' );
    ok( -f File::Spec->catfile( $tmpl_dir, 'xt', 'release', 'pod-syntax.t' ), 'pod-syntax.t exists' );
    ok( -f File::Spec->catfile( $tmpl_dir, 'xt', 'release', 'kwalitee.t' ), 'kwalitee.t exists' );

    # run again when directory exists
    ok( remove_tree($module_dir), 'removing module directory' );

    is( -d $module_dir, undef, 'module directory removed' );

    ok (@ARGV = ( '-m', 'Some::Test',), 'reset @ARGV' ); 

    ok( run(@ARGV), 'run() w/ module name and no template dir' );

    ok( remove_tree($mt_dir), 'remove test directory' );
}

SKIP: {
    skip( 'module directory does not exist', 2 ) unless -d $module_dir;

    ok( remove_tree($module_dir), 'removing module directory' );

    is( -d $module_dir, undef, 'module directory removed' );
}
