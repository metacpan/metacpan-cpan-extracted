# $Id: Makefile.PL,v 1.3 2001/06/04 10:05:27 matt Exp $

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
        'NAME'	=> 'AxKit::XSP::ESQL',
        'VERSION_FROM' => 'ESQL.pm', # finds $VERSION
        PREREQ_PM => { AxKit => 1.4, DBI => 1.0, AxKit::XSP::Util => 1.0 },
);
