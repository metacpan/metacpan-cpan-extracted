use ExtUtils::MakeMaker;

WriteMakefile(
    'dist'	=> {
	            PREOP	=> 'pod2text SpatialKey.pm | tee README > $(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
	            COMPRESS	=> 'gzip -9v',
	            SUFFIX	=> '.gz',
	           },
    'NAME'	=> 'DBIx::SpatialKey',
    'VERSION_FROM' => 'SpatialKey.pm',
    'LIBS'	=> [''],
    'DEFINE'	=> '',
    'INC'	=> '',
);
