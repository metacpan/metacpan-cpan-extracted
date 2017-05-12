use ExtUtils::MakeMaker;

use Canary::Stability Array::Heap => 1, 5.006;

WriteMakefile(
    dist	=> {
	            PREOP	=> 'pod2text Heap.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
	            COMPRESS	=> 'gzip -9v',
	            SUFFIX	=> '.gz',
	           },
    NAME => "Array::Heap",
    VERSION_FROM => "Heap.pm",
    CONFIGURE_REQUIRES => {
       "ExtUtils::MakeMaker" => 6.52,
       "Canary::Stability"   => 0,
    },
);

