use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Algorithm::SixDegrees',
    AUTHOR              => 'Pete Krawczyk <petek@cpan.org>',
    VERSION_FROM        => 'lib/Algorithm/SixDegrees.pm',
    ABSTRACT_FROM       => 'lib/Algorithm/SixDegrees.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Algorithm-SixDegrees-*' },
);
