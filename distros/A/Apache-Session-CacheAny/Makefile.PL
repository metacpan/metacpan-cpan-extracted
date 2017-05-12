use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Apache::Session::CacheAny',
    'VERSION_FROM' => 'lib/Apache/Session/CacheAny.pm', # finds $VERSION
    'PREREQ_PM' => {
	Apache::Session => 1.53,
	Test::More	=> 0.18,
	Cache::Cache	=> 0.08,
    },
);
