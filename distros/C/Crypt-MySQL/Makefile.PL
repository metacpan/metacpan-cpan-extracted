use strict;
use warnings;
use ExtUtils::MakeMaker;

link("lib/Crypt/MySQL.xs", "MySQL.xs");
WriteMakefile(
    NAME                => 'Crypt::MySQL',
    AUTHOR              => 'Tomohiro IKEBE <ikebe@shebang.jp>',
    VERSION_FROM        => 'lib/Crypt/MySQL.pm',
    ABSTRACT_FROM       => 'lib/Crypt/MySQL.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Digest::SHA1' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Crypt-MySQL-*' },
);
