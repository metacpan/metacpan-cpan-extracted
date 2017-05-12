use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Dancer2::Plugin::HTTP::Auth::Extensible',
    AUTHOR           => q{Theo van Hoesel <Th.J.v.Hoesel@THEMA-MEDIA.nl>},
    VERSION_FROM     => 'lib/Dancer2/Plugin/HTTP/Auth/Extensible.pm',
    ABSTRACT_FROM    => 'lib/Dancer2/Plugin/HTTP/Auth/Extensible.pm',
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
        'Dancer2::Plugin' => 0,
        'Dancer2::Plugin::Auth::Extensible' => 0,
        'HTTP::Headers::ActionPack::Authorization' => 0,
        'HTTP::Headers::ActionPack::WWWAuthenticate' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Dancer2-Plugin-HTTP-Auth-Extensible-*' },
);
