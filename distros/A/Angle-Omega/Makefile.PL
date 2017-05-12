use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Angle::Omega',
    AUTHOR              => q{Shankar M <msinfopl@gmail.com>},
    VERSION_FROM        => 'lib/Angle/Omega.pm',
    ABSTRACT_FROM       => 'lib/Angle/Omega.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Angle-Omega-*' },
);
