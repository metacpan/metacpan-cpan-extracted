use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Amazon::MWS',
    AUTHOR           => [q{Paul Driver <paul@plainblack.com>},
                         q{Phil Smith <phil.smith@rsdvd.com>},
                         q{Marco Pessotto <melmothx@gmail.com>},
                         q{Stefan Hornburg (Racke) <racke@linuxia.de>},
                     ],
    VERSION_FROM     => 'lib/Amazon/MWS.pm',
    ABSTRACT_FROM    => 'lib/Amazon/MWS.pm',
    LICENSE          => 'perl',
    PL_FILES         => {},
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::Deep'                => 0,
        'Test::More'                => 0,
        'Test::MockObject'          => 0,
        'Test::MockObject::Extends' => 0,
        'HTTP::Response'            => 0,
        'DBI' => 0,
        'DBD::SQLite' => 0,
    },
    PREREQ_PM => {
        'URI'            => 0, 
        'URI::Escape'    => 0,
        'HTTP::Request'  => 0,
        'LWP::UserAgent' => 0,
        'LWP::Protocol::https' => 0,
        'XML::Simple'    => 0,

        'DateTime'                  => 0,
        'DateTime::Format::ISO8601' => 0,

        'Readonly'         => 0,
        'Class::InsideOut' => 0,
        'Exception::Class' => 0,
        'Exporter'         => 0,

        'MIME::Base64'      => 0,
        'Digest::MD5'       => 0,
        'Digest::HMAC_SHA1' => 0,

        'namespace::clean' => 0,
        'Moo' => 0,
        'MooX::Types::MooseLike' => 0,
        'DBI' => 0,
        'DateTime' => 0,
        'SQL::Abstract' => 0,
        'Try::Tiny' => 0,
        'Path::Tiny' => 0,
        'XML::Compile::Schema' => 1.46,
        'DateTime::Format::ISO8601' => 0,
        'XML::LibXML::Simple' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Amazon-MWS-*' },
    META_MERGE => {
        resources => {
            repository => 'https://github.com/interchange/Amazon-MWS',
            bugtracker => 'https://github.com/interchange/Amazon-MWS/issues',
            IRC => 'irc://irc.freenode.net/#interchange',
        },
    },
);
