use strict;
use warnings FATAL => 'all';
use File::Spec::Functions 'catfile';
use Test::More tests => 4;
use Test::Script;

use_ok('App::Pocoirc::Status');
use_ok('App::Pocoirc');
use_ok('App::Pocoirc::ReadLine');

SKIP: {
    skip "There's no blib", 1 unless -d "blib" and -f catfile qw(blib script pocoirc);
    script_compiles(catfile('bin', 'pocoirc'));
};
