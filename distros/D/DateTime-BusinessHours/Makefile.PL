use strict;
use warnings;

use ExtUtils::MakeMaker;

if ( -e 'MANIFEST.SKIP' ) {
    system( 'pod2text lib/DateTime/BusinessHours.pm > README' );
}

WriteMakefile(
    DISTNAME            => 'DateTime-BusinessHours',
    NAME                => 'DateTime::BusinessHours',
    AUTHOR              => 'Antano Solar <solar345@gmail.com>',
    VERSION_FROM        => 'lib/DateTime/BusinessHours.pm',
    ABSTRACT_FROM       => 'lib/DateTime/BusinessHours.pm',
    MIN_PERL_VERSION    => '5.008001',
    (   eval { ExtUtils::MakeMaker->VERSION( 6.21 ) }
        ? ( LICENSE => 'perl' )
        : ()
    ),
    PREREQ_PM => {
        'DateTime' => 0,
        'Class::MethodMaker' => 0,
        'Test::More' => 0,
    },
);
