use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Date::Holidays::UK::EnglandAndWales',
    AUTHOR              => 'Lee Goddard <lgoddard-at-cpan.org>',
    VERSION_FROM        => 'lib/Date/Holidays/UK/EnglandAndWales.pm',
    ABSTRACT_FROM       => 'lib/Date/Holidays/UK/EnglandAndWales.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Tie::Hash'  => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Date-Holidays-UK-EnglandAndWales-*' },
);
