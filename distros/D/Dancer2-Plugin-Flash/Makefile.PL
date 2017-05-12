use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Dancer2::Plugin::Flash',
    AUTHOR           => q{Rakesh Kumar Shardiwal <rakesh.shardiwal@gmail.com>},
    VERSION_FROM     => 'lib/Dancer2/Plugin/Flash.pm',
    ABSTRACT_FROM    => 'lib/Dancer2/Plugin/Flash.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'Plack::Test' => 0,
        'HTTP::Request::Common' => 0,
    },
    PREREQ_PM => {
        'Dancer2::Plugin' => 0
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Dancer2-Plugin-Flash-*' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            bugtracker => {
                web => 'https://github.com/shardiwal/cpan-dancer2-plugin-Flash/issues'
            },
            homepage => 'http://perldancer.org/',
            repository => {
                type => 'git',
                url => 'git@github.com:shardiwal/cpan-dancer2-plugin-Flash.git',
                web => 'https://github.com/shardiwal/cpan-dancer2-plugin-Flash'
            }
        }
    },
);
