use strict;
use warnings;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME                => 'AnyEvent::Delay',
    AUTHOR              => '扶凯 <iakuf@163.com>',
    EXE_FILES           => [],
    PL_FILES            => {},
    LICENSE             => "perl",
    DISTNAME            => 'AnyEvent-Delay',
    VERSION_FROM        => 'lib/AnyEvent/Delay.pm',
    PREREQ_PM => {
        'Test::More'    => 0,
        'Moo'           => '0',
        'EV'            => '0',
        'AnyEvent'      => '0',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'AnyEvent-Delay-*' },   
    META_MERGE => {    
        resources => {     repository => 'https://github.com/iakuf/AnyEvent-Delay',     },    
    },
);
