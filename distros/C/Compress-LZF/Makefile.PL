use 5.008;

use ExtUtils::MakeMaker;

WriteMakefile(
    'dist'	=> {
	            PREOP	=> 'pod2text LZF.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
	            COMPRESS	=> 'gzip -9v',
	            SUFFIX	=> '.gz',
	           },
    'NAME'	=> 'Compress::LZF',
    'VERSION_FROM' => 'LZF.pm',
    'LIBS'	=> [''],
    'DEFINE'	=> '',
    'INC'	=> '',
);
