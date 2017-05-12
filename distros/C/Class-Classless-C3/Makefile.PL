use 5.006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Class::Classless::C3',
    VERSION_FROM      => 'lib/Class/Classless/C3.pm', # finds $VERSION
    PREREQ_PM         => {
		'Algorithm::C3' => 0.06,
		'Sub::Name' => 0.04,
	},
    ABSTRACT_FROM  => 'lib/Class/Classless/C3.pm', # retrieve abstract from module
    AUTHOR         => 'John Williams <smailliw@gmail.com>',
);
