use ExtUtils::MakeMaker;

require 5.005;

WriteMakefile(
    dist	=> {
	            PREOP	=> 'pod2text Twofish2.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
	            COMPRESS	=> 'gzip -9v',
	            SUFFIX	=> '.gz',
	           },
    NAME => "Crypt::Twofish2",
    VERSION_FROM => "Twofish2.pm",
);

