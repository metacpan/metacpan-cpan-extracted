use 5.006;

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'CallOfDuty::LANMapper',
    AUTHOR              => 'Peter Sinnott <link@redbrick.dcu.ie>',
    VERSION_FROM        => 'lib/CallOfDuty/LANMapper.pm',
    ABSTRACT_FROM       => 'lib/CallOfDuty/LANMapper.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'IO::Select' => 0,
	'IO::Socket::INET' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CallOfDuty-LANMapper-*' },
);
