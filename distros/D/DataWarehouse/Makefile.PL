use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'DataWarehouse',
    AUTHOR              => q{Nelson Ferraz <nferraz@gmail.com>},
    VERSION_FROM        => 'lib/DataWarehouse/Fact.pm',
    ABSTRACT_FROM       => 'lib/DataWarehouse.pod',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'DataWarehouse-*' },
);
