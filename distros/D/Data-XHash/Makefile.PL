use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Data::XHash',
    AUTHOR              => q{Brian Katzung <briank@kappacs.com>},
    VERSION_FROM        => 'lib/Data/XHash.pm',
    ABSTRACT_FROM       => 'lib/Data/XHash.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Data-XHash-*' },
);
