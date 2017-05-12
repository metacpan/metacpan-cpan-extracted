use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Class::Void',
    'VERSION_FROM'	=> 'Void.pm', # finds $VERSION
    'PREREQ_PM'		=> {
    	Test::Simple => 0.45
    }, # e.g., Module::Name => 1.1
);
