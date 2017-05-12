use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Catalyst::Plugin::EncryptID',
    AUTHOR           => q{Rakesh Kumar Shardiwal <rakesh.shardiwal@gmail.com>},
    VERSION_FROM     => 'lib/Catalyst/Plugin/EncryptID.pm',
    ABSTRACT_FROM    => 'lib/Catalyst/Plugin/EncryptID.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'Test::WWW::Mechanize::Catalyst' => 0
    },
    PREREQ_PM => {
        'Catalyst' => 0,
        'Catalyst::Controller' => 0,
        'Crypt::Blowfish' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Catalyst-Plugin-EncryptID-*' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            bugtracker => {
                web => 'https://github.com/shardiwal/cpan-catalyst-plugin-EncryptID/issues'
            },
            homepage => 'http://perldancer.org/',
            repository => {
                type => 'git',
                url => 'git@github.com:shardiwal/cpan-catalyst-plugin-EncryptID.git',
                web => 'https://github.com/shardiwal/cpan-catalyst-plugin-EncryptID'
            }
        }
    },
);
