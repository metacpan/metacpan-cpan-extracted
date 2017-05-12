use ExtUtils::MakeMaker;
# See ExtUtils::MakeMaker for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	'NAME'              => 'Cache::Memcached::Semaphore',
	'VERSION_FROM'      => 'Semaphore.pm', # finds $VERSION
	'ABSTRACT_FROM'		=> 'Semaphore.pm', # finds NAME
	'PREREQ_PM'         => {
		Cache::Memcached		=> 0,
		Time::HiRes			=> 0,
		Digest::MD5			=> 0,
	},
	($] >= 5.007003 ?    ## Add these new keywords supported since 5.005
		(AUTHOR     => 'Sergei A. Fedorov <zmij@cpan.org>') : ()),
);
