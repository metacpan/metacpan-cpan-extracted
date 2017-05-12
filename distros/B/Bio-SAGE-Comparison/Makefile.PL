# *%) $Id: Makefile.PL,v 1.1.1.1 2004/05/25 01:34:52 scottz Exp $

use ExtUtils::MakeMaker;

WriteMakefile(
   'DISTNAME'  => "Bio-SAGE-Comparison",
   'NAME'      => "Bio::SAGE::Comparison",
   'AUTHOR'    => 'Scott Zuyderduyn <scottz@bccrc.ca>',
   'ABSTRACT'  => 'Module to compare SAGE libraries.',
   'VERSION_FROM' => 'lib/Bio/SAGE/Comparison.pm',
   'PM'        => { 'lib/Bio/SAGE/Comparison.pm' => '$(INST_LIBDIR)/Comparison.pm', },
);

