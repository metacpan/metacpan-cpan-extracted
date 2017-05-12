use strict;
use warnings;
use ExtUtils::MakeMaker;
use 5.010;

WriteMakefile(
    NAME                => 'Data::Dmap',
    AUTHOR              => q{"Michael Zedeler" <"michael@zedeler.dk">},
    VERSION_FROM        => 'lib/Data/Dmap.pm',
    ABSTRACT_FROM       => 'lib/Data/Dmap.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Scalar::Util', => '1.22'
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Data-Dmap-*' },
);
