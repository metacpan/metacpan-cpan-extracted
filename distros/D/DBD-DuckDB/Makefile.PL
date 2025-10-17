use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'DBD::DuckDB',
    VERSION_FROM     => 'lib/DBD/DuckDB.pm',
    ABSTRACT_FROM    => 'lib/DBD/DuckDB.pm',
    AUTHOR           => q{Giuseppe Di Terlizzi <gdt@cpan.org>},
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => 5.010,
    PREREQ_PM        => {
        'DBI'                   => '1.623',
        'FFI::Platypus'         => '2.00',
        'FFI::CheckLib'         => '0.30',
        'FFI::Platypus::Record' => 0,
        'Scalar::Util'          => 0,
    },
    CONFIGURE_REQUIRES => {'ExtUtils::MakeMaker' => '0'},
    TEST_REQUIRES      => {'Test::More'          => '0', 'Alien::DuckDB' => 0},
    META_MERGE         => {
        'meta-spec' => {version => 2},
        'resources' => {
            bugtracker => {web => 'https://github.com/giterlizzi/perl-DBI-DuckDB/issues'},
            repository => {
                type => 'git',
                url  => 'git://github.com/giterlizzi/perl-DBI-DuckDB',
                web  => 'https://github.com/giterlizzi/perl-DBI-DuckDB'
            },
        },
        x_purl => 'pkg:cpan/GDT/DBI-DuckDB'
    },
    dist  => {COMPRESS => 'gzip -9f', SUFFIX => 'gz'},
    clean => {FILES    => 'DBI-DuckDB-*'},
);
