use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Acme::ctreptow',
    AUTHOR              => q{Craig Treptow <craig.treptow@gmail.com>},
    VERSION_FROM        => 'lib/Acme/ctreptow.pm',
    ABSTRACT_FROM       => 'lib/Acme/ctreptow.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Acme-ctreptow-*' },
);
