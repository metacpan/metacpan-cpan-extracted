use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Cloudflare::API',
    VERSION_FROM     => 'lib/Cloudflare/API.pm',
    ABSTRACT         => 'Manage Cloudflare compute and storage resources from Perl',
    AUTHOR           => 'Andrew Speer <andrew.speer@isolutions.com.au>',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.010',
    EXE_FILES        => ['bin/cloudflare-api'],
    PREREQ_PM        => {
        'HTTP::API::Core' => '1.01',
        'IO::Socket::SSL' => 0,
        'JSON::PP'        => 0,
        'Digest::SHA'     => 0,
        'MIME::Base64'    => 0
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.64'
    },
    TEST_REQUIRES => {
        'Test::More' => '0.88',
        'File::Temp' => 0
    },
    META_MERGE => {
        'meta-spec' => {version => 2},
        resources   => {
            bugtracker => {
                web => 'https://github.com/aspeer/pm-Cloudflare-API/issues'
            },
            homepage   => 'https://github.com/aspeer/pm-Cloudflare-API',
            repository => {
                type => 'git',
                url  => 'https://github.com/aspeer/pm-Cloudflare-API.git',
                web  => 'https://github.com/aspeer/pm-Cloudflare-API'
            }
        }
    }
);
