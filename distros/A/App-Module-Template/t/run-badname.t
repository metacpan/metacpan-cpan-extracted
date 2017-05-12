#!perl

use strict;
use warnings;

use Test::More tests => 5;
use Test::Exception;

use File::Path qw/remove_tree/;
use File::Spec;

ok( @ARGV = (
    '-t',
    File::Spec->abs2rel( File::Spec->catdir( File::Spec->curdir, 't', '.module-template', 'templates' ) ),
    '-c',
    File::Spec->abs2rel( File::Spec->catfile( File::Spec->curdir, 't', '.module-template', 'config' ) ),
    '-m',
    'some::test',
), 'set @ARGV' );

use_ok( 'App::Module::Template', 'run' );

ok( my $module_dir = File::Spec->catdir( File::Spec->curdir, 'some-test' ), 'set module directory' );

# make sure we have a clean environment
SKIP: {
    skip( 'module directory does not exist', 1 ) unless -d $module_dir;
    ok( remove_tree($module_dir), 'remove module directory' );
}

throws_ok{ run(@ARGV) } qr/'some::test' is an all lower-case namespace/, 'run croaks on bad module name';
