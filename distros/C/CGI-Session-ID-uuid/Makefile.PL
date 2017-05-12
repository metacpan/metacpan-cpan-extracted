##
##  Makefile.PL: Module Build Specification
##

use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'CGI::Session::ID::uuid',
    VERSION_FROM  => 'uuid.pm',
    ABSTRACT      => 'UUID based CGI Session Identifiers',
    PM            => { 'uuid.pm'  => '$(INST_LIBDIR)/uuid.pm' },
    PREREQ_PM     => {},
    AUTHOR        => 'Ralf S. Engelschall <rse@engelschall.com>'
);

