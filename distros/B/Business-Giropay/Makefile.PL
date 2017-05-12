use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Business::Giropay',
    AUTHOR             => q{Peter Mottram (SysPete) <peter@sysnix.com>},
    VERSION_FROM       => 'lib/Business/Giropay.pm',
    ABSTRACT_FROM      => 'lib/Business/Giropay.pm',
    LICENSE            => 'perl',
    PL_FILES           => {},
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'aliased'         => 0,
        'Test::Exception' => 0,
        'Test::More'      => '0.94',
    },
    PREREQ_PM => {
        'Carp'             => 0,
        'Digest::HMAC_MD5' => 0,
        'HTTP::Tiny'       => 0,
        'IO::Socket::SSL'  => '1.56',    # needed by HTTP::Tiny for https
        'JSON::MaybeXS'    => 0,
        'Module::Runtime'  => 0,
        'Moo'              => '1.001000',
        'namespace::clean' => 0,
        'Type::Tiny'       => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Business-Giropay-*' },
    test => { TESTS => join( ' ', ( glob('t/*.t'), glob('t/*/*.t') ) ) },
    META_MERGE => {
        resources => {
            repository => 'https://github.com/interchange/Business-Giropay.git',
            bugtracker =>
              'https://github.com/interchange/Business-Giropay/issues',
            IRC => 'irc://irc.freenode.net/#interchange',
        },
    },
);
