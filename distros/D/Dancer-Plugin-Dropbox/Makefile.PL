use 5.010001;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Dancer::Plugin::Dropbox',
    AUTHOR           => q{Marco Pessotto <melmothx@gmail.com>},
    VERSION_FROM     => 'lib/Dancer/Plugin/Dropbox.pm',
    ABSTRACT_FROM    => 'lib/Dancer/Plugin/Dropbox.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.010001,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
                  'Dancer' => 1.311,
                  'Format::Human::Bytes' => 0,
                  'File::Spec' => 0,
                  'DateTime' => 0,
                  'URI::Escape' => 0,
                  'File::Slurp' => 0,
                 },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Dancer-Plugin-Dropbox-*' },
);
