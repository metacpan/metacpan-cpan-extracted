use ExtUtils::MakeMaker;

# See ExtUtils::MakeMaker perldoc for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    NAME         => 'Class::Interface',
    VERSION_FROM => 'lib/Class/Interface.pm', # finds 
    AUTHOR       => 'Hartog C. de Mik, { Simplic.IT } <hartog.de.mik@simplic.it>',
    ABSTRACT     => 'A class for implementing/extending interfaces/abstracts in Perl.',
    PREREQ_PM    => { 'Carp' => 0,
                    },
);
