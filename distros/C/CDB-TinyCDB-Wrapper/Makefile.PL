use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'CDB::TinyCDB::Wrapper',
    AUTHOR              => q{Michael Alan Dorman <mdorman@ironicdesign.com>},
    VERSION_FROM        => 'lib/CDB/TinyCDB/Wrapper.pm',
    ABSTRACT_FROM       => 'lib/CDB/TinyCDB/Wrapper.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'CDB::TinyCDB' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CDB-TinyCDB-Wrapper-* t/test.cdb*' },
);
