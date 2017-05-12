use 5.004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME => 'Class::STL::Containers',
	VERSION_FROM => 'lib/Class/STL/Containers.pm', # finds $VERSION
	INST_SCRIPT => 'scripts',
	INST_LIB => 'lib',
	PREREQ_PM => {}, # e.g., Module::Name => 1.1
	dist =>
	{
		SUFFIX => ".gz",
		DIST_DEFAULT => 'all tardist',
		COMPRESS => "gzip -9vf",
#		TARFLAGS => '--owner=root --group=users cvf'
	},
	($] >= 5.005 ?     ## Add these new keywords supported since 5.005
	(ABSTRACT_FROM  => 'docs/class-stl-containers.pod', # retrieve abstract from module
	AUTHOR         => 'm gaffiero <gaffie@users.sourceforge.net>') : ()),
);
