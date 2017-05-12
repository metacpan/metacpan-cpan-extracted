use strict;
use warnings FATAL => 'all';
use File::Spec::Functions 'catfile';
use Test::More tests => 5;
use Test::Script;
use_ok 'App::Bondage';
use_ok 'App::Bondage::Away';
use_ok 'App::Bondage::Client';
use_ok 'App::Bondage::Recall';

SKIP: {
    skip "There's no blib", 1 unless -d "blib" and -f catfile qw(blib script bondage);
    script_compiles(catfile('bin', 'bondage'));
};
