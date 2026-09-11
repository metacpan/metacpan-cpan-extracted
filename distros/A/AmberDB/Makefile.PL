use 5.016;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'AmberDB',
    AUTHOR           => 'Maruf Cetin <marufcetin@gmail.com>',
    VERSION_FROM     => 'lib/AmberDB.pm',
    ABSTRACT_FROM    => 'lib/AmberDB.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.016',
    PL_FILES         => {},
    EXE_FILES        => [
        'bin/amberdb_setup.pl',
        'bin/amberdb_daemon.pl',
    ],
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::More' => '0.98',
        'File::Temp' => '0',
        'FindBin'    => '0',
    },
    PREREQ_PM => {
        'DB_File'      => '0',
        'Carp'         => '0',
        'Fcntl'        => '0',
        'Encode'       => '0',
        'Time::Local'  => '0',
        'Time::HiRes'  => '0',
        'File::Spec'   => '0',
        'File::Path'   => '0',
        'List::Util'   => '0',
        'Getopt::Long' => '0',
        'parent'       => '0',
        'Archive::Tar' => '0',
        'Digest::SHA'  => '0',
        'JSON::PP'     => '0',
        'Hash::Util'   => '0',
    },
    TEST_REQUIRES => {
        'Test::More'   => '0.98',
        'File::Temp'   => '0',
        'FindBin'      => '0',
        'Archive::Tar' => '0',
        'JSON::PP'     => '0',
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        no_index    => {
            directory => [
                'lib/AmberDB/Base',
                'lib/AmberDB/Locale/Lang',
            ],
            file => [
                'lib/AmberDB/Base.pm',
                'lib/AmberDB/Locale/Currency.pm',
            ],
            namespace => [
                'AmberDB::Base',
                'AmberDB::Locale::Lang',
            ],
            package => [
                'AmberDB::Base',
                'AmberDB::Locale::Currency',
            ],
        },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/marufcetin/amberdb.git',
                web  => 'https://github.com/marufcetin/amberdb',
            },
            bugtracker => {
                web => 'https://github.com/marufcetin/amberdb/issues',
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean => { FILES => 'AmberDB-* MYMETA.*' },
);
