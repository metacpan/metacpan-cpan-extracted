use ExtUtils::MakeMaker;

require 5.005;

WriteMakefile(
    dist	=> {
	            PREOP	=> 'pod2text FEC.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
	            COMPRESS	=> 'gzip -9v',
	            SUFFIX	=> '.gz',
	           },
    NAME => "Algorithm::FEC",
    VERSION_FROM => "FEC.pm",
    OBJECT       => q<$(BASEEXT)$(OBJ_EXT) fec8$(OBJ_EXT) fec16$(OBJ_EXT)>,
);

