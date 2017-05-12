use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Date::Holidays::PT',
    AUTHOR              => 'Jose Castro <cog@cpan.org>',
    VERSION_FROM        => 'lib/Date/Holidays/PT.pm',
    ABSTRACT_FROM       => 'lib/Date/Holidays/PT.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Date::Holidays::Super' => 0,
        'Date::Easter' => 0,
        'Time::JulianDay' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Date-Holidays-PT-*' },
);
