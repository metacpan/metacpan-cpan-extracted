use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Artifactory::Client',
    AUTHOR             => q{Satoshi Yagi <satoshi.yagi@yahoo.com>},
    VERSION_FROM       => 'lib/Artifactory/Client.pm',
    ABSTRACT_FROM      => 'lib/Artifactory/Client.pm',
    LICENSE            => 'artistic_2',
    PL_FILES           => {},
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'WWW::Mechanize' => 0,
    },
    PREREQ_PM => {
        'HTTP::Request::StreamingUpload' => 0,
        'JSON::MaybeXS'                  => 0,
        'LWP::UserAgent'                 => 0,
        'Moose'                          => 2.0604,
        'MooseX::StrictConstructor'      => 0,
        'namespace::autoclean'           => 0,
        'Path::Tiny'                     => 0,
        'URI::Escape'                    => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Artifactory-Client-*' },
);
