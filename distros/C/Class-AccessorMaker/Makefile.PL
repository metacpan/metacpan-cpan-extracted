use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Class::AccessorMaker',
    VERSION_FROM => 'lib/Class/AccessorMaker.pm', # finds $VERSION
    AUTHOR       => 'Hartog C. de Mik (hartog@2organize.com)',
    ABSTRACT     => 'An accessor method maker',
);
