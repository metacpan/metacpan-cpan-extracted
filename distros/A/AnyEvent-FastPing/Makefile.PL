use ExtUtils::MakeMaker;

use 5.008;

WriteMakefile(
    dist	   => {
	            PREOP	=> 'pod2text FastPing.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
	            COMPRESS	=> 'gzip -9v',
	            SUFFIX	=> '.gz',
	           },
    PREREQ_PM      => {
       AnyEvent      => 0,
       common::sense => 3.4,
    },
    NAME           => "AnyEvent::FastPing",
    VERSION_FROM   => "FastPing.pm",
    LIBS           => ["-lpthread -lm"],
    EXE_FILES      => ["bin/fastping"],
);

