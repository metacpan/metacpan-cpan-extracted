use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'ACME::Error::HTML',
    'VERSION_FROM'	=> 'HTML.pm', # finds $VERSION
    'PREREQ_PM'		=> { HTML::FromText => 0.01 }, # e.g., Module::Name => 1.1
);
