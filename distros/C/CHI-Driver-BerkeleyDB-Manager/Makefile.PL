use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'CHI::Driver::BerkeleyDB::Manager',
    AUTHOR              => q{James Rouzier <rouzier@gmail.com>},
    VERSION_FROM        => 'lib/CHI/Driver/BerkeleyDB/Manager.pm',
    ABSTRACT_FROM       => 'lib/CHI/Driver/BerkeleyDB/Manager.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'BerkeleyDB::Manager' => 0,
        'CHI' => 0,
        'CHI::Driver' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CHI-Driver-BerkeleyDB-Manager-*' },
);
