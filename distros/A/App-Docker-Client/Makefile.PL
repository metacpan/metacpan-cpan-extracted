use 5.16.0;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'App::Docker::Client',
    AUTHOR             => q{Mario Zieschang <mziescha@cpan.org>},
    VERSION_FROM       => 'lib/App/Docker/Client.pm',
    ABSTRACT_FROM      => '',
    LICENSE            => 'artistic_2',
    PL_FILES           => {},
    MIN_PERL_VERSION   => 5.16.0,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    PREREQ_PM => {
        'URI'                                => 1.71,
        'Carp'                               => 0,
        'HTTP::Request'                      => 6.01,
        'JSON'                               => 2.90,
        'LWP::UserAgent'                     => 6.12,
        'LWP::Protocol::https'               => 6.01,
        'LWP::Protocol::http::SocketUnixAlt' => 0,
        'AnyEvent'                           => 0,
        'AnyEvent::Socket'                   => 0,
        'AnyEvent::HTTP'                     => 0,
    },
    TEST_REQUIRES => {
        'Test::More' => 0,
        'File::Spec' => 0,
        'FindBin'    => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/mziescha/App-Docker-Client.git',
                web  => 'https://github.com/mziescha/App-Docker-Client',
            },
        }
    },
    dist  => { COMPRESS => 'gzip -9f',            SUFFIX => 'gz', },
    clean => { FILES    => 'App-Docker-Client-*', 'cover_db', },
);
