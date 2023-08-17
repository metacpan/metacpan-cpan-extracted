use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'BankDetails::India',
    AUTHOR             => q{Rohit R Manjrekar <manjrekarrohit76@gmail.com>},
    VERSION_FROM       => 'lib/BankDetails/India.pm',
    ABSTRACT_FROM      => 'lib/BankDetails/India.pm',
    MIN_PERL_VERSION   => 5.006,
    LICENSE            => 'mit',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    PREREQ_PM => {
        'Carp'                  => 0,
        'CHI'                   => 0,
        'Digest::MD5'           => 0,
        'LWP::UserAgent'        => 0,
        'LWP::Protocol::https'  => 0,
        'Moose'                 => 0,
        'Sereal'                => 0,
        'JSON'                  => 0,
        'XML::Simple'           => 0,
        'Cwd'                   => 0,
    },
    TEST_REQUIRES => {
        'Test::More'        => 0,
        'Test::Exception'   => 0,
        'Test::MockObject'  => 0,
        'HTTP::Response'    => 0,
    },
    "test" => {
        "TESTS" => "t/*.t"
    },
    META_MERGE => {
        "meta-spec" => { version => 1.0 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/rmanjrekar/Webservice.git',
                web  => 'https://github.com/rmanjrekar/Webservice',
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'BankDetails-India-*' },
);
