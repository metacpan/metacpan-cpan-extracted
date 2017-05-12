use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Convert::RACE',
    'VERSION_FROM' => 'lib/Convert/RACE.pm', # finds $VERSION
    'PREREQ_PM' => {
	'Convert::Base32' => 0.02,
    },
);

