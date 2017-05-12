use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Dancer::Plugin::Auth::Github',
    AUTHOR           => q{Gideon Israel Dsouza <gideon@cpan.org>},
    VERSION_FROM     => 'lib/Dancer/Plugin/Auth/Github.pm',
    ABSTRACT_FROM    => 'lib/Dancer/Plugin/Auth/Github.pm',
    LICENSE          => 'perl',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'JSON' => 2.53,
        'LWP::UserAgent' => 6.04,
        'Dancer' => 1.3110
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Dancer-Plugin-Auth-Github-*' },
);
