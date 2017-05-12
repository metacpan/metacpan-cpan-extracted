#!perl

use strict;
use warnings;

use Test::More tests => 6;
use Test::Exception;

use File::Path qw/remove_tree/;
use File::Spec;

use_ok( 'App::Module::Template', 'run' );

ok( my $module_dir = File::Spec->catdir( File::Spec->curdir, 'Some-Test' ), 'set module directory' );

# make sure we have a clean environment
SKIP: {
    skip( 'module directory does not exist', 1 ) unless -d $module_dir;
    ok( remove_tree($module_dir), 'removing module directory' );
}

throws_ok{ run(@ARGV) } qr/-m <Module::Name> is required\. exiting/, 'run() exists with no -m';

ok( @ARGV = ('-m'), 'set @ARGV with no module name' );

throws_ok{ run(@ARGV) } qr/-m <Module::Name> is required\. exiting/, 'run() exists with no -m';
