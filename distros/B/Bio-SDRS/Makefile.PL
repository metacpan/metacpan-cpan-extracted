use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Bio::SDRS',
    VERSION_FROM      => 'lib/Bio/SDRS.pm', # finds $VERSION
    PREREQ_PM         => { "Inline" => 0.45, # e.g., Module::Name => 1.1
			   "Inline::C" => 0,
		           "Math::NumberCruncher" => "5.00", 
			   "Statistics::Distributions" => 1.02
			 },
    EXE_FILES         => [ 'sdrs.pl' ],
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Bio/SDRS.pm', # retrieve abstract from module
		AUTHOR         => join(', ',
				       'Robert Bruccoleri <bruc@acm.org>',
				       'Ruiru Ji <ruiruji@gmail.com>',
				       'Nathan O. Siemers <nathan.siemers@bms.com>',
				       'Lei Ming <lei.ming@bms.com>',
				       'Liang Schweizer <liang.schweizer@bms.com>'))
     : ()),
);
