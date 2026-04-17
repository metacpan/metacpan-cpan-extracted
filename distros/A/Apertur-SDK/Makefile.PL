use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Apertur::SDK',
    VERSION_FROM     => 'lib/Apertur/SDK.pm',
    ABSTRACT_FROM    => 'lib/Apertur/SDK.pm',
    AUTHOR           => 'Apertur <support@apertur.ca>',
    LICENSE          => 'mit',
    MIN_PERL_VERSION => '5.026',
    PREREQ_PM        => {
        'LWP::UserAgent'        => 0,
        'JSON'                  => 0,
        'HTTP::Request::Common' => 0,
        'Digest::SHA'           => 0,
        'MIME::Base64'          => 0,
    },
    TEST_REQUIRES => {
        'Test::More' => '0.96',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            homepage   => 'https://apertur.ca',
            repository => {
                type => 'git',
                url  => 'https://github.com/Apertur-dev/apertur-perl.git',
                web  => 'https://github.com/Apertur-dev/apertur-perl',
            },
            bugtracker => {
                web => 'https://github.com/Apertur-dev/apertur-perl/issues',
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean => { FILES    => 'Apertur-SDK-*' },
);
