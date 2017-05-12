use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME              => 'Apache::Session::Memcached',
	VERSION_FROM      => 'lib/Apache/Session/Memcached.pm', # finds $VERSION
	PREREQ_PM         => {
		'Cache::Memcached' => 1.14,
		'Apache::Session' => 1.54,
	}, # e.g., Module::Name => 1.1
	($] >= 5.005 ?     ## Add these new keywords supported since 5.005
		(ABSTRACT_FROM => 'lib/Apache/Session/Memcached.pm', # retrieve abstract from module
		AUTHOR         => 'Enrico Sorcinelli <enrico at sorcinelli.it>') : ()),
);
