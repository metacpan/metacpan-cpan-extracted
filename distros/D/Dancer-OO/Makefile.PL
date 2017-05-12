use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Dancer::OO::Dancer',
    AUTHOR              => q{JAMHED <ip@ncom-ufa.ru>},
    VERSION_FROM        => 'lib/Dancer/OO/Dancer.pm',
    ABSTRACT_FROM       => 'lib/Dancer/OO/Dancer.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Dancer'     => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Dancer-OO-Dancer-*' },
);
