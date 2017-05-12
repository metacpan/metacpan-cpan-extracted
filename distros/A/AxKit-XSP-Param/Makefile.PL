# $Id: Makefile.PL,v 1.2 2001/06/04 10:08:43 matt Exp $

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'AxKit::XSP::Param',
    'VERSION_FROM' => 'Param.pm', # finds $VERSION
    'PREREQ_PM' => { AxKit => 1.4,
                   },
);
