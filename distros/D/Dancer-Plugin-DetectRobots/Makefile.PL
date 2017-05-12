use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Dancer::Plugin::DetectRobots',
    AUTHOR        => q{Dan Busarow <dan@buildingonline.com>},
    VERSION_FROM  => 'lib/Dancer/Plugin/DetectRobots.pm',
    PREREQ_PM => {
        'Test::More'            => 0,
        'Dancer'                => 1.175,
        'Regexp::Assemble'      => 0,
    },
);
