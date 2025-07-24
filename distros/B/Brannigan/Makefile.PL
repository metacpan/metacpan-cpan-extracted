use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Brannigan',
    AUTHOR           => q{Ido Perlmuter <ido@ido50.net>},
    VERSION_FROM     => 'lib/Brannigan.pm',
    ABSTRACT_FROM    => 'lib/Brannigan.pm',
    LICENSE          => 'apache_2_0',
    MIN_PERL_VERSION => '5.008',
    
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    
    BUILD_REQUIRES => {
        'Test2::V0' => '0',
    },
    
    PREREQ_PM => {
        'Hash::Merge' => '0',
    },
    
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/ido50/Brannigan.git',
                web  => 'https://github.com/ido50/Brannigan',
            },
            bugtracker => {
                web => 'https://github.com/ido50/Brannigan/issues',
            },
        },
    },
    
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Brannigan-*' },
);