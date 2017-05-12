use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Acme::Lingua::Strine::Perl',
    'VERSION_FROM'	=> 'Perl.pm', # finds $VERSION
    'PREREQ_PM'		=> {Filter::Simple => 0}, # e.g., Module::Name => 1.1
);
