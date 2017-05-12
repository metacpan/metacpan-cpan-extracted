use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Business::TW::TSIB::VirtualAccount',
    AUTHOR        => 'Cornelius <c9s@aiink.com>',
    VERSION_FROM  => 'lib/Business/TW/TSIB/VirtualAccount.pm',
    ABSTRACT_FROM => 'lib/Business/TW/TSIB/VirtualAccount.pm',
    PL_FILES      => {},
    PREREQ_PM => {
        'Test::More'            => 0,
        'Class::Accessor'       => 0,
        'DataTime'              => 0,
        'Class::Accessor::Fast' => 0,
        },
    dist => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Business-TW-TSIB-VirtualAccount-*' },
);
