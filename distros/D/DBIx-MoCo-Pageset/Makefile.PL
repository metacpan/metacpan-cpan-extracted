use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'DBIx::MoCo::Pageset',
    AUTHOR              => 'syushi matsumoto <matsumoto@alink.co.jp>',
    VERSION_FROM        => 'lib/DBIx/MoCo/Pageset.pm',
    ABSTRACT_FROM       => 'lib/DBIx/MoCo/Pageset.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'DBIx::MoCo' => 0,
        'Data::Pageset' => 1.02,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'DBIx-MoCo-Pageset-*' },
);
