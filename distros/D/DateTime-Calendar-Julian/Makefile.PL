use ExtUtils::MakeMaker;
WriteMakefile(
    NAME		    => 'DateTime::Calendar::Julian',
    VERSION_FROM	=> 'lib/DateTime/Calendar/Julian.pm',
    PREREQ_PM		=> { DateTime => 0.08 },
    ABSTRACT        => 'DateTime object in the Julian calendar',
    AUTHOR          => 'Eugene van der Pijll <pijll@gmx.net>',
);
