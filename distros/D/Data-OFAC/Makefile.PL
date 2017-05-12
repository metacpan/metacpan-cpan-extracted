use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Data::OFAC',
    AUTHOR           => q{tyler hardison <tyler@seraph-net.net>},
    VERSION_FROM     => 'lib/Data/OFAC.pm',
    ABSTRACT_FROM    => 'lib/Data/OFAC.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Text::CSV' => 0,
        'LWP' => 0,
        'DBD::SQLite' => 0,
        'Archive::Extract' => 0,
        'Archive::Zip' => 0,
        'DBIx::Class::Schema' => 0,
        'DBIx::Class::PhoneticSearch' => 0
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Data-OFAC-*' },
);
