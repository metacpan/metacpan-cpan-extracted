use 5.012;
use strict;
use warnings;

use Module::Build::WithXSpp;

my $build = Module::Build::WithXSpp->new(
    module_name         => 'Compress::DSRC',
    license             => 'gpl',
    dist_author         => q{Jeremy Volkening <jdv*at*base2bio*dot*com>},
    needs_compiler      => 1,
    build_requires => {
        'Test::More' => 0,
        'ExtUtils::Typemaps::ObjectMap' => '0',
    },
    extra_typemap_modules => {
        'ExtUtils::Typemaps::ObjectMap' => '0',
    },
    extra_compiler_flags => [qw/-O2 -DNDEBUG -D_FILE_OFFSET_BITS=64 -D_LARGEFILE64_SOURCE -Wall -shared -fPIC -Wno-unused-variable -std=c++11/],
    extra_linker_flags => [qw/-lpthread/ ],
    meta_merge => {
        resources => {
            repository => 'https://github.com/jvolkening/p5-Compress-DSRC'
        }
    },
);
$build->create_build_script;
