use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'DBIx::Raw',
    AUTHOR           => q{Adam Hopkins <srchulo@cpan.org>},
    VERSION_FROM     => 'lib/DBIx/Raw.pm',
    ABSTRACT_FROM    => 'lib/DBIx/Raw.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'Test::Carp' => 0,
        'DBD::SQLite' => 0,
        'YAML::XS' => 0,
        'Cwd' => 0,
    },
    PREREQ_PM => {
        'Mouse'              => 0,
        'DBI'              => 0,
        'Config::Any' => 0,
        'Crypt::CBC' => 0,
        'Crypt::Blowfish' => 0,
        'MIME::Base64' => 0,
        'Digest::MD5' => 0,
        'Carp' => 0,
        'List::Util' => 0,
        'Crypt::Mode::CBC::Easy' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'DBIx-Raw-*' },
);
