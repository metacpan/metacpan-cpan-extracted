use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Centrifugo::Client',
    AUTHOR             => q{Benoît Chauvet <benoit.chauvet@gmail.com>},
    VERSION_FROM       => 'lib/Centrifugo/Client.pm',
    ABSTRACT_FROM      => 'lib/Centrifugo/Client.pm',
    LICENSE            => 'MIT',
    PL_FILES           => {},
    MIN_PERL_VERSION   => 5.10.0,
    CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => 0, },
    BUILD_REQUIRES     => { 
        'Test::More' => 0,
        },
    PREREQ_PM          => {
        'AnyEvent::WebSocket::Client' => 0.40,
        'AnyEvent::HTTP' => 0,
        'Digest::SHA' => 0,
        'JSON' => 0,
    },
    dist       => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean      => { FILES    => 'Centrifugo-*' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/Orabig/centrifugo-perl-client.git',
                web  => 'https://github.com/Orabig/centrifugo-perl-client',
            },
        },
    },
);
