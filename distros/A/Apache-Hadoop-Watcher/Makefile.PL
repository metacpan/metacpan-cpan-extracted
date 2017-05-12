use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Apache::Hadoop::Watcher',
    VERSION_FROM      => 'lib/Apache/Hadoop/Watcher.pm', # finds $VERSION
    PREREQ_PM         => {
		'JSON' => '2.15',
		'Data::Dumper' => '2.124',
		'IO::Socket::INET' => '1.31',
		'LWP::UserAgent' => '5.833',
		'XML::Twig' => '3.34',
        }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Apache/Hadoop/Watcher.pm', # retrieve abstract from module
       AUTHOR         => 'Snehasis Sinha <snehasis@cpan.org>') : ()),
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
          ? ('LICENSE'=> 'perl')
                : ()),
    dist              => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean             => { FILES => 'Apache-Hadoop-Watcher-*' },
);
