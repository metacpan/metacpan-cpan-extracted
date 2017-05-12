##
##  Makefile.PL: Module Build Specification
##

use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'CGI::Session::ID::UUID',
    VERSION_FROM  => 'UUID.pm',
    ABSTRACT      => 'UUID based CGI Session Identifiers',
    PM            => { 'UUID.pm'  => '$(INST_LIBDIR)/UUID.pm' },
    PREREQ_PM     => {},
    AUTHOR        => 'Ralf S. Engelschall <rse@engelschall.com>'
);

