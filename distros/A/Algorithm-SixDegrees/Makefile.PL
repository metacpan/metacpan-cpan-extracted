use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Algorithm::SixDegrees',
    AUTHOR              => 'Peter Krawczyk <petek@cpan.org>',
    VERSION_FROM        => 'lib/Algorithm/SixDegrees.pm',
    ABSTRACT_FROM       => 'lib/Algorithm/SixDegrees.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Scalar::Util' => 0,
        'Test::More'   => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Algorithm-SixDegrees-*' },
);
