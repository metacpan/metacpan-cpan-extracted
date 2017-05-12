use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Array::Lock',
    'VERSION_FROM'	=> 'Lock.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.007003 ?    ## Add these new keywords supported since 5.005
      (AUTHOR     => 'Gyan Kapur <gkapur@cpan.org>') : ()),
);

