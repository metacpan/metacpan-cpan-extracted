use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Data::Org::Template',
    AUTHOR           => q{Michael Roberts <michael@vivtek.com>},
    VERSION_FROM     => 'lib/Data/Org/Template.pm',
    ABSTRACT_FROM    => 'lib/Data/Org/Template.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'Iterator::Records' => 0,
        'Data::Dumper' => 0,
    },
    PREREQ_PM => {
        #'Iterator::Records' => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
               type => 'git',
               url  => 'https://github.com/Vivtek/Data-Org-Template.git',
               web  => 'https://github.com/Vivtek/Data-Org-Template',
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Data-Org-Template-*' },
);
