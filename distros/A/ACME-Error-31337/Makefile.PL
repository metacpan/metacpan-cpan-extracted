use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'ACME::Error::31337',
    'VERSION_FROM'	=> '31337.pm', # finds $VERSION
    'PREREQ_PM'		=> { ACME::Error => 0.01, Lingua::31337 => 0.01 }, # e.g., Module::Name => 1.1
);
