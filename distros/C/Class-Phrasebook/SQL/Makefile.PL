use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Class::Phrasebook::SQL',
    'VERSION_FROM'	=> 'SQL.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, 
);
