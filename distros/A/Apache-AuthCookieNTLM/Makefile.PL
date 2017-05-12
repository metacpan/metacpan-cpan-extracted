use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Apache::AuthCookieNTLM',
    'VERSION_FROM'	=> 'lib/Apache/AuthCookieNTLM.pm', # finds $VERSION
    'PREREQ_PM'		=> {
		'Test::More'	     => 0.01,
		'Apache::AuthenNTLM' => 2.07,
		'Apache::Request'    => 0.01,
		'Apache::Cookie'     => 0.01,	
		'Apache::Constants'  => 0.01,
	}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      ( AUTHOR     => 'Leo Lapworth <llap@cuckoo.org>, Francoise Dehinbo') : ()),
);
