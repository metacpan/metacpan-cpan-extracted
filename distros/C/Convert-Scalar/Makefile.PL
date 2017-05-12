use ExtUtils::MakeMaker;

use Canary::Stability Convert::Scalar => 1, 5.008;

WriteMakefile(
    dist	=> {
	            PREOP	=> 'pod2text Scalar.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
	            COMPRESS	=> 'gzip -9v',
	            SUFFIX	=> '.gz',
	           },
    NAME => "Convert::Scalar",
    VERSION_FROM => "Scalar.pm",
    CONFIGURE_REQUIRES => { "ExtUtils::MakeMaker" => 6.52, "Canary::Stability" => 0 },
);

