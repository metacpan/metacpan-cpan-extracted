use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'ACME::Error::Translate',
    'VERSION_FROM'	=> 'Translate.pm', # finds $VERSION
    'PREREQ_PM'		=> { ACME::Error => 0.01, Lingua::Translate => 0.01 }, # e.g., Module::Name => 1.1
);
