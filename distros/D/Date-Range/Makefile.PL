use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME          => 'Date::Range',
	VERSION_FROM  => 'lib/Date/Range.pm',
	ABSTRACT_FROM => 'lib/Date/Range.pm',
	PREREQ_PM     => {
		'Date::Simple' => 0.03,
		'Test::More'   => 0.04,
	},
	AUTHOR => 'Tony Bowden <kasei@tmtm.com>',
);
