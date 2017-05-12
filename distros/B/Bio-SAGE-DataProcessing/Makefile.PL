# *%) $Id: Makefile.PL,v 1.3 2004/06/20 00:01:20 scottz Exp $

use ExtUtils::MakeMaker;

WriteMakefile(
   'DISTNAME'  => "Bio-SAGE-DataProcessing",
   'NAME'      => "Bio::SAGE::DataProcessing",
   'AUTHOR'    => 'Scott Zuyderduyn <scottz@bccrc.ca>',
   'ABSTRACT'  => 'Module to process raw data generated from SAGE libraries.',
   'VERSION_FROM' => 'lib/Bio/SAGE/DataProcessing.pm',
   'PM'        => { 'lib/Bio/SAGE/DataProcessing.pm' => '$(INST_LIBDIR)/DataProcessing.pm',
                    'lib/Bio/SAGE/DataProcessing/Filter.pm' => '$(INST_LIBDIR)/DataProcessing/Filter.pm',
                    'lib/Bio/SAGE/DataProcessing/AveragePhredFilter.pm' => '$(INST_LIBDIR)/DataProcessing/AveragePhredFilter.pm',
                    'lib/Bio/SAGE/DataProcessing/MinimumPhredFilter.pm' => '$(INST_LIBDIR)/DataProcessing/MinimumPhredFilter.pm',
                  },
   #'PREREQ_PM' => { 'Statistics::Distributions' => 1.02, },
);

