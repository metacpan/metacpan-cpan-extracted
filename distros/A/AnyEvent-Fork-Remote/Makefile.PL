use ExtUtils::MakeMaker;

use 5.008;

WriteMakefile(
    dist	=> {
	            PREOP	=> 'pod2text Remote.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
	            COMPRESS	=> 'gzip -9v',
	            SUFFIX	=> '.gz',
	           },
    NAME => "AnyEvent::Fork::Remote",
    VERSION_FROM => "Remote.pm",
    PREREQ_PM => {
       common::sense   => 3.6,
       AnyEvent        => 6,
       Proc::FastSpawn => 1.1,
#       AnyEvent::Fork  => 0.6, # not _really_ a dependency, but pretty much really one
#       Guard           => 1,
    },
);

