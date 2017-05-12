use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Data::TemporaryBag',
    'VERSION_FROM'	=> 'TemporaryBag.pm', # finds $VERSION
    'PREREQ_PM'		=> {File::Temp => 0.12, }, # e.g., Module::Name => 1.1
);
