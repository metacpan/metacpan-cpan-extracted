use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Apache::No404Proxy',
    'VERSION_FROM' => 'lib/Apache/No404Proxy.pm', # finds $VERSION
    'PREREQ_PM' => {
	'LWP::UserAgent' 	=> 1.80,
	'URI' 			=> 1.15,
#	'WWW::Cache::Google' 	=> 0.02,
	'mod_perl' 		=> 1.21,
	'SOAP::Lite'            => 0,
    },
);
