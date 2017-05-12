use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Dancer2::Template::TemplateFlute',
    AUTHOR        => q{Stefan Hornburg (Racke) <racke@linuxia.de>},
    VERSION_FROM  => 'lib/Dancer2/Template/TemplateFlute.pm',
    ABSTRACT_FROM => 'lib/Dancer2/Template/TemplateFlute.pm',
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002
        ? ( 'LICENSE' => 'perl' )
        : () ),
    PL_FILES  => {},
    BUILD_REQUIRES => {
        'Test::More'            => '0.94',      # subtest
        'Test::Deep'            => 0,
        'HTTP::Cookies'         => 0,
        'HTTP::Request::Common' => 0,
        'Plack'                 => '1.0029',    # Plack::Test OO interface
        'XML::Twig'             => 0,
    },
    PREREQ_PM => {
        'Carp'                 => 0,
        'Dancer2'              => '0.200000',
        'Dancer2::Core::Types' => 0,
        'Module::Runtime'      => 0,
        'Moo'                  => '2.000000',
        'namespace::clean'     => 0,
        'Scalar::Util'         => 0,
        'Template::Flute'      => 0.0140,
        'Try::Tiny'            => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url => 'https://github.com/interchange/Dancer2-Template-TemplateFlute.git',
                web => 'https://github.com/interchange/Dancer2-Template-TemplateFlute',
                bugtracker => 'https://github.com/interchange/Dancer2-Template-TemplateFlute/issues',
            },
            IRC => 'irc://irc.perl.org/#dancer',
        },
    },
    dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Dancer2-Template-TemplateFlute-*' },
);
