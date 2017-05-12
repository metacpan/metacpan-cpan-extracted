use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME              => 'Data::FormValidator::Filters::HTMLScrubber',
	VERSION_FROM      => 'lib/Data/FormValidator/Filters/HTMLScrubber.pm', # finds $VERSION
	PREREQ_PM         => {
		HTML::Scrubber => 0.08
	},
	($] >= 5.005 ?     ## Add these new keywords supported since 5.005
		(ABSTRACT_FROM  => 'lib/Data/FormValidator/Filters/HTMLScrubber.pm', # retrieve abstract from module
		AUTHOR         => 'Enrico Sorcinelli <bepi@perl.it>') : ()),
);
