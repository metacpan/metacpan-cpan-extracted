use strict;
use warnings FATAL => 'all';
use File::Spec::Functions 'catfile';
use Test::More tests => 4;
use Test::Script;

use_ok('App::Pocosi::Status');
use_ok('App::Pocosi');
use_ok('App::Pocosi::ReadLine');

SKIP: {
    skip "There's no blib", 1 unless -d "blib" and -f catfile qw(blib script pocosi);
    script_compiles(catfile('bin', 'pocosi'));
};
