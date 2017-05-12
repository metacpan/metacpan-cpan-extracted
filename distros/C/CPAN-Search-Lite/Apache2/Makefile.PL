use strict;
my %opts = (
	    NAME => 'CSL_Apache',
            VERSION_FROM => 'Apache2/CPAN/Query.pm',
            PMLIBDIRS => [qw(Apache2)],
	    dist   => {
			 SUFFIX   => 'gz',
			 COMPRESS => 'gzip -9f',
			},
	   );

require ModPerl::MM;
require Apache::TestMM;
import Apache::TestMM qw(test clean);

Apache::TestMM::filter_args();

Apache::TestMM::generate_script('t/TEST');

ModPerl::MM::WriteMakefile( %opts);
