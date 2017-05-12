use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Acme::MyFirstModule::ddeimeke',
    AUTHOR              => q{Dirk Deimeke <dirk@deimeke.net>},
    VERSION_FROM        => 'lib/Acme/MyFirstModule/ddeimeke.pm',
    ABSTRACT_FROM       => 'lib/Acme/MyFirstModule/ddeimeke.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Acme-MyFirstModule-ddeimeke-*' },
);
