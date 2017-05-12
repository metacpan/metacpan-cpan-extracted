use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'DateTime::Format::Oracle',
    AUTHOR        => 'Nathan Gray <kolibrie@cpan.org>',
    VERSION_FROM  => 'lib/DateTime/Format/Oracle.pm',
    ABSTRACT_FROM => 'lib/DateTime/Format/Oracle.pm',
    LICENSE       => 'perl',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::More'                => 0,
        'DateTime'                  => 0,
        'DateTime::Format::Builder' => 0,
	'Convert::NLS_DATE_FORMAT'  => 0.03,
    },
);
