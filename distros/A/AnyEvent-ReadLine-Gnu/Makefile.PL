use ExtUtils::MakeMaker;

use 5.008;

WriteMakefile(
    dist	=> {
	            PREOP	=> 'pod2text Gnu.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
	            COMPRESS	=> 'gzip -9v',
	            SUFFIX	=> '.gz',
	           },
    NAME => "AnyEvent::ReadLine::Gnu",
    VERSION_FROM => "Gnu.pm",
    EXE_FILES => ["bin/rltelnet"],
    PREREQ_PM => {
       common::sense  => 3,
       AnyEvent       => 6,
       Term::ReadLine::Gnu  => 1.2,
    },
);

