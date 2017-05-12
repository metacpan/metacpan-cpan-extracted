# -*- mode:Perl -*-
# $Id: Makefile.PL,v 1.1 1997/04/22 04:15:48 chip Beta $
#

use ExtUtils::MakeMaker;
unshift @INC;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'         => 'Acme::PIA::Export',
    'VERSION_FROM' => 'Export.pm', # finds $VERSION
    'AUTHOR'       => 'Chr. Winter <chrwin@cpan.org>',
    'PREREQ_PM'    => {
    	'IO::Socket' => 0
    },
    'PREREQ_FATAL' => 1,
);
