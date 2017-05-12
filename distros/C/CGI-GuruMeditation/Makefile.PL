##
##  Makefile.PL: Module Build Specification
##

use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'CGI::GuruMeditation',
    VERSION_FROM  => 'GuruMeditation.pm',
    ABSTRACT      => 'Guru Meditation for CGIs',
    PM            => { 'GuruMeditation.pm'  => '$(INST_LIBDIR)/GuruMeditation.pm' },
    PREREQ_PM     => {},
    AUTHOR        => 'Ralf S. Engelschall <rse@engelschall.com>'
);

