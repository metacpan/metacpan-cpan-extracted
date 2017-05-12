use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'App::XUL',
    VERSION_FROM      => 'lib/App/XUL.pm', # finds $VERSION
    PREREQ_PM         => { # e.g., Module::Name => 1.1
    	'Directory::Scratch::Structured' => 0,
    	'File::Copy::Recursive' => 0,
    	'Data::Dumper::Concise' => 0,
    	'Time::HiRes' => 0,
    	'Socket' => 0,
    	'IO::Socket' => 0,
    	'LWP::Simple' => 0,
    	'URI::Escape' => 0,
    	'JSON' => 0,
    	'Data::Dumper' => 0,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/App/XUL.pm', # retrieve abstract from module
       AUTHOR         => 'Tom Kirchner <tk@apple.com>') : ()),
);
