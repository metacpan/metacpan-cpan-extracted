use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Cisco::Accounting',
    AUTHOR              => 'Maarten Wallraf <perl@2nms.com>',
    VERSION_FROM        => 'lib/Cisco/Accounting.pm',
    ABSTRACT       => 'Cisco and IPCAD ip accounting parser and aggregator',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
		'Net::Telnet::Wrapper'	=> 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Cisco-Accounting-*' },
);
