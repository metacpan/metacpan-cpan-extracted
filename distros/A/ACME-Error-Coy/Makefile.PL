use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'ACME::Error::Coy',
    'VERSION_FROM'	=> 'Coy.pm', # finds $VERSION
    'PREREQ_PM'		=> { Coy => 0.01 }, # e.g., Module::Name => 1.1
);
