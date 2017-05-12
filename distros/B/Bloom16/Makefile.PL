use Inline::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteInlineMakefile(
    'NAME'		=> 'Bloom16',
    'VERSION_FROM'	=> 'Bloom16.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
);
