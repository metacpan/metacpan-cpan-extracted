use 5.008008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Config::Yacp',
    VERSION_FROM      => 'lib/Config/Yacp.pm', # finds $VERSION
    PREREQ_PM         => { Object::InsideOut => 0,
    			   Parse::RecDescent => 0,
			   Data::Dumper      => 0,
			   Fcntl             => 0,
			   Carp              => 0,
			   Test::More        => 0,
			   Test::Pod         => 0,
			   Test::Harness     => 0,
}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Config/Yacp.pm', # retrieve abstract from module
       AUTHOR         => 'Thomas Stanley <Thomas_J_Stanley@msn.com>') : ()),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
);
