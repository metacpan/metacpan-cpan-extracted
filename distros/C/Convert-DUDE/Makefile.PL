use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Convert::DUDE',
    'VERSION_FROM' => 'lib/Convert/DUDE.pm', # finds $VERSION
    'PREREQ_PM' => {
	'Unicode::String' => 2.06,
    },
);
