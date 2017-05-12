use ExtUtils::MakeMaker;

use Canary::Stability Crypt::Ed25519 => 1;

WriteMakefile(
    dist	=> {
	            PREOP	=> 'pod2text Ed25519.pm | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
	            COMPRESS	=> 'gzip -9v',
	            SUFFIX	=> '.gz',
	           },
    NAME => "Crypt::Ed25519",
    VERSION_FROM => "Ed25519.pm",
    CONFIGURE_REQUIRES => { "ExtUtils::MakeMaker" => 6.52, "Canary::Stability" => 0 },
);

