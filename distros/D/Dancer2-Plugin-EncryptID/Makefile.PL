use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Dancer2::Plugin::EncryptID',
    AUTHOR           => q{Rakesh Kumar Shardiwal <rakesh.shardiwal@gmail.com>},
    VERSION_FROM     => 'lib/Dancer2/Plugin/EncryptID.pm',
    ABSTRACT_FROM    => 'lib/Dancer2/Plugin/EncryptID.pm',
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
        'Crypt::Blowfish' => 0,
        'Dancer2::Plugin' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Dancer2-Plugin-EncryptID-*' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            bugtracker => {
                web => 'https://github.com/shardiwal/cpan-dancer2-plugin-EncryptID/issues'
            },
            homepage => 'http://perldancer.org/',
            repository => {
                type => 'git',
                url => 'git@github.com:shardiwal/cpan-dancer2-plugin-EncryptID.git',
                web => 'https://github.com/shardiwal/cpan-dancer2-plugin-EncryptID'
            }
        }
    },
);
