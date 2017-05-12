use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'BioUtil',
    AUTHOR             => q{Wei Shen <shenwei356@gmail.com>},
    VERSION_FROM       => 'lib/BioUtil.pm',
    ABSTRACT_FROM      => 'lib/BioUtil.pm',
    LICENSE            => 'Artistic_2_0',
    PL_FILES           => {},
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => 0, },
    BUILD_REQUIRES     => { 'Test::More' => 0, },
    PREREQ_PM          => {
        'JSON'           => 0,
        'List::Util'     => 0,
        'Time::HiRes'    => 0,
        'File::Path'     => 0,
        'Encode'         => 0,
        'File::Find'     => 0,
        'File::Basename' => 0,

    },
    dist       => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean      => { FILES    => 'BioUtil-*' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/shenwei356/BioUtil.git',
                web  => 'https://github.com/shenwei356/BioUtil',
            },
        },
    },
);
