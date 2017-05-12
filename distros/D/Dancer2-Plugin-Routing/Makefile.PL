use 5.10.0;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Dancer2::Plugin::Routing',
    AUTHOR             => q{Mario Zieschang <mziescha@cpan.org>},
    VERSION_FROM       => 'lib/Dancer2/Plugin/Routing.pm',
    LICENSE            => 'artistic_2',
    PL_FILES           => {},
    MIN_PERL_VERSION   => 5.10.0,
    CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => 0, },
    PREREQ_PM          => {
        'Dancer2'                     => 0,
        'Dancer2::Plugin::RootURIFor' => 0,
        'Ref::Util'                   => 0,
    },
    TEST_REQUIRES => {
        'HTTP::Request::Common'   => 0,
        'Test::CheckManifest'     => 0,
        'Test::Pod::Coverage'     => 0,
        'Test::Requires'          => 0,
        'Test::Pod'               => 0,
        'Test::More'              => 0,
        'Plack::Builder'          => 0,
        'Plack::Test'             => 0,
        'Pod::Coverage::TrustPod' => 0,
        'Pod::Usage'              => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/mziescha/Dancer2-Plugin-Routing.git',
                web  => 'https://github.com/mziescha/Dancer2-Plugin-Routing',
            },
        }
    },
    dist  => { COMPRESS => 'gzip -9f',                   SUFFIX => 'gz', },
    clean => { FILES    => [ 'Dancer2-Plugin-Routing-*', 'cover_db' ] },
);
