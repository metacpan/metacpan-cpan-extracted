use strict;
require ExtUtils::MakeMaker;
my %opts = (
	    NAME => 'CSL',
            VERSION_FROM => 'CPAN/Search/Lite/Query.pm',
            PMLIBDIRS => [qw(CPAN PPM SOAP Apache2)],
	    dist   => {
			 SUFFIX   => 'gz',
			 COMPRESS => 'gzip -9f',
			},
	   );

WriteMakefile( %opts);
