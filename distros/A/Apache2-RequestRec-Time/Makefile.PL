
use 5.008000;

use ModPerl::MM ();
use Apache2::Build ();

use Apache::TestMM qw(clean test);
Apache::TestMM::filter_args();
Apache::TestMM::generate_script('t/TEST');

ModPerl::MM::WriteMakefile(
	NAME => 'Apache2::RequestRec::Time',
	AUTHOR => 'Jan Pazdziora',
	LICENSE => 'Apache License, Version 2.0',
	VERSION_FROM => 'lib/Apache2/RequestRec/Time.pm',
	ABSTRACT_FROM => 'lib/Apache2/RequestRec/Time.pm',
	PREREQ_PM => { 'Test::More' => 0, },
	INC => Apache2::Build->new->apxs(-q => 'EXTRA_INCLUDES'),
	clean => { FILES => 't/TEST', },
	dist => { POSTOP => '$(MV) $(DISTVNAME).tar$(SUFFIX) ..' },
);

