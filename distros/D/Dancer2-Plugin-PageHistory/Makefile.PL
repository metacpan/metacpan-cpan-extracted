use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Dancer2::Plugin::PageHistory',
    AUTHOR       => q{Peter Mottram (SysPete) <peter@sysnix.com>},
    VERSION_FROM => 'lib/Dancer2/Plugin/PageHistory.pm',
    ABSTRACT => 'Collect interesting pages a user has visited in the session',
    LICENSE  => 'perl',
    PL_FILES => {},
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'File::Path'            => 0,
        'HTTP::Cookies'         => 0,
        'HTTP::Request::Common' => 0,
        'JSON::MaybeXS'         => 0,
        'Plack'                 => '1.0031',
        'Test::Fatal'           => 0,
        'Test::More'            => '0.94', # subtest
    },
    PREREQ_PM => {
        'Carp'                  => 0,
        'Dancer2'               => '0.200000',
        'Dancer2::Core::Types'  => 0,
        'Dancer2::Plugin'       => 0,
        'Data::Structure::Util' => '0.16',
        'Moo'                   => '2.000',
        'namespace::clean'      => 0,
        'Scalar::Util'          => 0,
        'Sub::Quote'            => 0,
        'URI'                   => 0,
    },
    dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Dancer2-Plugin-PageHistory-* t/TestApp/sessions' },
    META_MERGE => {
        resources => {
            repository =>
              'https://github.com/SysPete/Dancer2-Plugin-PageHistory',
            bugtracker =>
              'https://github.com/SysPete/Dancer2-Plugin-PageHistory/issues',
            IRC => 'irc://irc.perl.org/#dancer',
        },
    },
);
