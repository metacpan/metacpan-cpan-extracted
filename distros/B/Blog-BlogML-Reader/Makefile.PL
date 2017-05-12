use 5.008006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME			=> 'Blog::BlogML::Reader',
	VERSION_FROM	=> 'lib/Blog/BlogML/Reader.pm', # finds $VERSION
	PREREQ_PM		=> {
		XML::Parser::Expat	=> 0,
		HTTP::Date			=> 0,
		Carp				=> 0,
	},
	($] >= 5.005 ?	## Add these new keywords supported since 5.005
	(ABSTRACT_FROM	=> 'lib/Blog/BlogML/Reader.pm', # retrieve abstract from module
	AUTHOR			=> 'Michael Mathews <mmathews@cpan.org>') : ()),
);
