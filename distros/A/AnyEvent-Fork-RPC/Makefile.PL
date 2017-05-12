use ExtUtils::MakeMaker;

use 5.008;

WriteMakefile(
    dist	=> {
	            PREOP	=> 'pod2text RPC.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
	            COMPRESS	=> 'gzip -9v',
	            SUFFIX	=> '.gz',
	           },
    NAME => "AnyEvent::Fork::RPC",
    VERSION_FROM => "RPC.pm",
    TEST_REQUIRES => {
       AnyEvent::Fork  => 0.6,
    },
    PREREQ_PM => {
       common::sense   => 3.6,
       AnyEvent        => 6,
       Guard           => 1,
    },
);

