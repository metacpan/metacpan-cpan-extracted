use 5.005;

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'Compass::Points',
    VERSION_FROM    => 'lib/Compass/Points.pm',
    PREREQ_PM       => {},
    ABSTRACT_FROM   => 'lib/Compass/Points.pm',
    AUTHOR          => 'Simon Bertrang <janus@cpan.org>',
    LICENSE         => 'perl',
    META_MERGE      => {
        resources       => {
            license         => 'http://dev.perl.org/licenses/',
            repository      => 'https://github.com/sbertrang/compass-points.git',
            bugtracker      => 'https://github.com/sbertrang/compass-points/issues',
        },
    },
);

# vim: ts=4 sw=4 et:
