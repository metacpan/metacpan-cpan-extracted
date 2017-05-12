use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Backtick::AutoChomp',
    AUTHOR              => 'David Westbrook <dwestbrook@gmail.com>',
    VERSION_FROM        => 'lib/Backtick/AutoChomp.pm',
    ABSTRACT_FROM       => 'lib/Backtick/AutoChomp.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'     => 0,
	'PPI'            => 0,
	'Filter::Simple' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Backtick-AutoChomp-*' },
);
