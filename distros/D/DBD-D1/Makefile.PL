use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'DBD::D1',
    AUTHOR           => 'Aldo Montes Zapata <amontes@cpan.org>',
    VERSION_FROM     => 'lib/DBD/D1.pm',
    ABSTRACT_FROM    => 'lib/DBD/D1.pm',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.014',
    PREREQ_PM => {
        'DBI'             => '1.640',
        'HTTP::Tiny'      => '0.070',
        'JSON::PP'        => '2.97',
        'IO::Socket::SSL' => '1.42',
        'Net::SSLeay'     => '1.49',
    },
    BUILD_REQUIRES => { 'Test::More' => '0.98' },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean => { FILES    => 'DBD-D1-*' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/amzt/DBD-D1.git',
                web  => 'https://github.com/amzt/DBD-D1',
            },
            bugtracker => {
                web => 'https://github.com/amzt/DBD-D1/issues',
            },
        },
    },
);
