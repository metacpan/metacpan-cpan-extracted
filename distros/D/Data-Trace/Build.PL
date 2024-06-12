#!/bin/env perl

use 5.006;
use strict;
use warnings;
use Module::Build;
Module::Build->VERSION( '0.4004' );

sub _readme {
    print "Building README\n";
    system "pod2markdown lib/Data/Trace.pm > README.md";
}
_readme();

my $builder = Module::Build->new(
    module_name        => 'Data::Trace',
    license            => 'artistic_2',
    dist_author        => q{Tim Potapov <tim.potapov@gmail.com>},
    dist_version_from  => 'lib/Data/Trace.pm',
    release_status     => 'stable',
    configure_requires => {
        'Module::Build' => '0.4004',
    },
    test_requires => {
        'Test::More' => '0',
    },
    requires => {
        'perl'         => '5.014',
        'Data::DPath'  => '0.58',
        'Time::Moment' => '0.44',
    },
    add_to_cleanup => [
        'Data-Trace-*',
        'MANIFEST*.bak',
        'README*',
        'blib/',
        'pod2htmd.tmp',
    ],
    meta_merge     => {
        resources => {
            bugtracker => 'https://github.com/poti1/data-trace/issues',
            repository => 'https://github.com/poti1/data-trace',
        },
    },
);

$builder->create_build_script();
