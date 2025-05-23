use ExtUtils::MakeMaker;

use Canary::Stability Convert::BER::XS => 1, 5.008009;

WriteMakefile(
    dist	=> {
	            PREOP	=> 'pod2text XS.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
	            COMPRESS	=> 'gzip -9v',
	            SUFFIX	=> '.gz',
	           },
    NAME => "Convert::BER::XS",
    VERSION_FROM => "XS.pm",
    CONFIGURE_REQUIRES => { "ExtUtils::MakeMaker" => 6.52, "Canary::Stability" => 0 },
    PREREQ_PM    => {
       common::sense => 3.74,
    },
);

