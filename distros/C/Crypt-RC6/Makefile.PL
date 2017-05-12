#! /usr/local/bin/perl

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile being created.
WriteMakefile(
	        dist => {
	                   PREOP => 'pod2text RC6.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
	                COMPRESS => 'gzip -9v',
	                  SUFFIX => '.gz',
	                },
            NAME => "Crypt::RC6",
    VERSION_FROM => "RC6.pm"
);
