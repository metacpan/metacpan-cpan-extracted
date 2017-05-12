use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Advent::Bundles',
    AUTHOR              => 'David Westbrook <dwestbrook@gmail.com>',
    VERSION_FROM        => 'lib/Advent/Bundles.pm',
    ABSTRACT_FROM       => 'lib/Advent/Bundles.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Advent-Bundles-*' },
);
