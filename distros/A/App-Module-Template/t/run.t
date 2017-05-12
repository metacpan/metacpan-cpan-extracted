#!perl

use strict;
use warnings;

use Test::More tests => 6;
use Test::Exception;

use File::Path qw/remove_tree/;
use File::Spec;

ok( @ARGV = (
    '-t',
    File::Spec->abs2rel( File::Spec->catdir( File::Spec->curdir, 't', '.module-template', 'templates' ) ),
    '-c',
    File::Spec->abs2rel( File::Spec->catfile( File::Spec->curdir, 't', '.module-template', 'config' ) ),
    '-m',
    'Some::Test',
), 'set @ARGV' );

use_ok( 'App::Module::Template', 'run' );

ok( my $module_dir = File::Spec->catdir( File::Spec->curdir, 'Some-Test' ), 'set module directory' );

# make sure we have a clean environment
SKIP: {
    skip( 'module directory does not exist', 1 ) unless -d $module_dir;
    ok( remove_tree($module_dir), 'removing module directory' );
}

ok( run(@ARGV), 'run() w/ module name' );

SKIP: {
    skip( 'module directory does not exist', 1 ) unless -d $module_dir;
    ok( remove_tree($module_dir), 'removing module directory' );
}
