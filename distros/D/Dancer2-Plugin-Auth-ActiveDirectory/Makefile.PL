use 5.10.0;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Dancer2::Plugin::Auth::ActiveDirectory',
    AUTHOR             => q{Mario Zieschang <mziescha@cpan.org>},
    VERSION_FROM       => 'lib/Dancer2/Plugin/Auth/ActiveDirectory.pm',
    LICENSE            => 'artistic_2',
    PL_FILES           => {},
    MIN_PERL_VERSION   => 5.10.0,
    CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => 0, },
    PREREQ_PM          => {
        'Carp'                  => 0,
        'Dancer2'               => 0,
        'Net::LDAP'             => 0,
        'Auth::ActiveDirectory' => 0,
    },
    TEST_REQUIRES => {
        'Pod::Coverage::TrustPod' => 0,
        'Pod::Usage'              => 0,
        'Test::CheckManifest'     => 0,
        'Test::Pod::Coverage'     => 0,
        'Test::Requires'          => 0,
        'Test::Pod'               => 0,
        'Test::Net::LDAP'         => 0,
        'Test::Net::LDAP::Mock'   => 0,
        'HTTP::Request::Common'   => 0,
        'Plack::Test'             => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/mziescha/Dancer2-Plugin-Auth-ActiveDirectory.git',
                web  => 'https://github.com/mziescha/Dancer2-Plugin-Auth-ActiveDirectory',
            },
        }
    },
    dist  => { COMPRESS => 'gzip -9f',                                SUFFIX => 'gz', },
    clean => { FILES    => [ 'Dancer2-Plugin-Auth-ActiveDirectory-*', 'cover_db' ] },
);
