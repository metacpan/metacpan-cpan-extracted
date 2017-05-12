use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'DBSchema::Normalizer',
    'VERSION_FROM'	=> 'Normalizer.pm', # finds $VERSION
    'PREREQ_PM'		=> {DBI => 0, 'DBD::mysql' => 0 }, # e.g., Module::Name => 1.1
);
