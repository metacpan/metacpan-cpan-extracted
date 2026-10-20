use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'App::SlimPacker',
    VERSION_FROM     => 'lib/App/SlimPacker.pm',
    ABSTRACT         => 'Fatpack-style bundler with PPI-based minification for standalone Perl scripts',
    LICENSE          => 'artistic_2',
    AUTHOR           => 'Nicolas Mendoza <mendoza@pvv.ntnu.no>',
    MIN_PERL_VERSION => '5.010',
    EXE_FILES        => ['bin/slimpack', 'bin/minify'],
    PREREQ_PM        => {
        'PPI'              => 0,
        'App::FatPacker'   => 0,
        'Module::CoreList' => 0,
    },
    TEST_REQUIRES    => {
        'Test::More' => '0.88',
    },
    META_MERGE       => {
        resources => {
            repository => 'https://github.com/nicomen/App-SlimPacker',
            bugtracker => 'https://github.com/nicomen/App-SlimPacker/issues',
        },
    },
);
