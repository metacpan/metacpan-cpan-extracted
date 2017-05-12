use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Apache::AxKit::Provider::DOM',
    'VERSION_FROM'	=> 'DOM.pm', # finds $VERSION
    'PREREQ_PM'		=> {'AxKit' => 1.6}, # e.g., Module::Name => 1.1
);
