use ExtUtils::MakeMaker;

use 5.008;

WriteMakefile(
    dist	=> {
	            PREOP	=> 'pod2text Pool.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
	            COMPRESS	=> 'gzip -9v',
	            SUFFIX	=> '.gz',
	           },
    NAME => "AnyEvent::Fork::Pool",
    VERSION_FROM => "Pool.pm",
    TEST_REQUIRES => {
       AnyEvent::Fork       => 0.6,
    },
    PREREQ_PM => {
       Task::Weaken         => 1,
       common::sense        => 3.6,
       Guard                => 1,
       Array::Heap          => 3,
       AnyEvent             => 6,
       AnyEvent::Fork::RPC  => 0,
    },
);

