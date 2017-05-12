use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Acme::Yoda',
    VERSION_FROM => 'lib/Acme/Yoda.pm', # finds $VERSION
    AUTHOR       => 'Christian Brink (cbrink@schmidy.com)',
    ABSTRACT     => '',
    PREREQ_PM    => { Lingua::LinkParser => 0},	      
);
