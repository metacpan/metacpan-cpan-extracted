use ExtUtils::MakeMaker;

require 5.008;

WriteMakefile(
    dist	=> {
	            PREOP	=> 'pod2text FCP.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
	            COMPRESS	=> 'gzip -9v',
	            SUFFIX	=> '.gz',
	           },
    NAME => "AnyEvent::FCP",
    VERSION_FROM => "FCP.pm",
#    EXE_FILES    => [qw(bin/fmd)],
    PREREQ_PM    => {
                       AnyEvent        => 2.6,
                       common::sense   => 0,
                    },
);

