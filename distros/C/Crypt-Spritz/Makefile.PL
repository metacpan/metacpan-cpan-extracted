use ExtUtils::MakeMaker;

use Canary::Stability Crypt::Spritz => 1;

WriteMakefile(
    dist	=> {
	            PREOP	=> 'pod2text Spritz.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
	            COMPRESS	=> 'gzip -9v',
	            SUFFIX	=> '.gz',
	           },
    NAME => "Crypt::Spritz",
    VERSION_FROM => "Spritz.pm",
    CONFIGURE_REQUIRES => { "ExtUtils::MakeMaker" => 6.52, "Canary::Stability" => 0 },
    OPTIMIZE => "-ggdb",
);

