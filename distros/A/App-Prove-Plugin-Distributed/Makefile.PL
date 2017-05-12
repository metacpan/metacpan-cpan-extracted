use 5.005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'App::Prove::Plugin::Distributed',
    VERSION_FROM      => 'lib/App/Prove/Plugin/Distributed.pm', # finds $VERSION
    BUILD_REQUIRES => {
	'Test::Builder' => 0,
	'Test::Fatal' => 0,
	'Test::Requires' => 0,
    },
    META_MERGE => {
	recommends => {
	    'Net::Address::IP::Local' => 0,
	    'PBS::Client' => 0,
	    'Net::Ping' => 0,
	},
    },
    PREREQ_PM         => {
			    'App::Prove' => 3.22,
			    'Carp' => 0,
			    'Cwd' => 0,
			    'Getopt::Long' => 0,
			    'IO::Select' => 0,
			    'IO::Socket::INET' => 0,
			    'Sys::Hostname' => 0,
			    'Test::More' => 0,
			    'Config' => 0,
			    'File::Spec' => 0,
			    'IO::File' => 0,
			     
                         }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/App/Prove/Plugin/Distributed.pm', # retrieve abstract from module
       AUTHOR         => 'Shin Leong <lsf@cpan.org>') : ()),
);
