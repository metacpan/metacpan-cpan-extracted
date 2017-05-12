use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'		=> 'Audio::LADSPA::Buffer',
    'VERSION_FROM'	=> '../LADSPA.pm', # finds $VERSION
    'PREREQ_PM'		=> {'Test::More' => 0, }, # e.g., Module::Name => 1.i
);
