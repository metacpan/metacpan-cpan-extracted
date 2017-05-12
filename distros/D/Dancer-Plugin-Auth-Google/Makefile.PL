use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Dancer::Plugin::Auth::Google',
    AUTHOR              => 'Breno G. de Oliveira <garu@cpan.org>',
    VERSION_FROM        => 'lib/Dancer/Plugin/Auth/Google.pm',
    ABSTRACT_FROM       => 'lib/Dancer/Plugin/Auth/Google.pm',
    LICENSE             => 'perl',
    PL_FILES            => {},
    PREREQ_PM => {
        'JSON'            => 0,
        'Dancer'          => 0,
        'Furl'            => 0,
        'IO::Socket::SSL' => 0,
        'Carp'            => 0,
        'URI'             => 0,
        'Test::More'      => 0,
        'Try::Tiny'       => 0,
    },
    META_MERGE => {
        resources => {
            repository => 'http://github.com/garu/Dancer-Plugin-Auth-Google',
        },
    },
    dist      => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean     => { FILES => 'Dancer-Plugin-Auth-Google-*' },
);
