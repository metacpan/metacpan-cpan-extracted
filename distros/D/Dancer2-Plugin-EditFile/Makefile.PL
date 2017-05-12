use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Dancer2::Plugin::EditFile',
    AUTHOR           => q{Hagop "Jack" Bilemjian <jck000@gmail.com>},
    VERSION_FROM     => 'lib/Dancer2/Plugin/EditFile.pm',
    ABSTRACT_FROM    => 'lib/Dancer2/Plugin/EditFile.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Carp'                 => 0,
        'Dancer2'              => 0,
        'Dancer2::Core::Types' => 0,
        'Dancer2::Plugin'      => 0,
        'Moo'                  => 0,
        'Moo::Role'            => 0,
        'YAML'                 => 0, 
        'Session::Token'       => 0,
        'Try::Tiny'            => 0,
        'File::Copy'      => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Dancer2-Plugin-EditFile-*' },
    META_MERGE => {
        resources => {
            repository => 'https://github.com/jck000/Dancer2-Plugin-EditFile',
            bugtracker => 'https://github.com/jck000/Dancer2-Plugin-EditFile/issues',
            homepage   => 'https://github.com/jck000/Dancer2-Plugin-EditFile/',
        },
    },
);

