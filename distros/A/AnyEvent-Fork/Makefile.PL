use ExtUtils::MakeMaker;

use 5.008;

WriteMakefile(
    dist	=> {
	            PREOP	=> 'pod2text Fork.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
	            COMPRESS	=> 'gzip -9v',
	            SUFFIX	=> '.gz',
	           },
    NAME => "AnyEvent::Fork",
    VERSION_FROM => "Fork.pm",
    PREREQ_PM => {
       common::sense   => 3.6,
       Proc::FastSpawn => 0.1,
       IO::FDPass      => 0.2,
       AnyEvent        => 6,
    },
);

