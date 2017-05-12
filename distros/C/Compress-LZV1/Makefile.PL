use ExtUtils::MakeMaker;

WriteMakefile(
    'dist'	=> {
	            PREOP	=> 'pod2text LZV1.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
	            COMPRESS	=> 'gzip -9v',
	            SUFFIX	=> '.gz',
	           },
    'NAME'	=> 'Compress::LZV1',
    'VERSION_FROM' => 'LZV1.pm',
    'LIBS'	=> [''],
    'DEFINE'	=> '',
    'INC'	=> '',
);
