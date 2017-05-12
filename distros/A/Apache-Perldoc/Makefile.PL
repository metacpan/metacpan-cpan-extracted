use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Apache::Perldoc',
    'VERSION_FROM'	=> 'lib/Apache/Perldoc.pm', # finds $VERSION
    'PREREQ_PM'		=> { Test::More }, # e.g., Module::Name => 1.1
);
