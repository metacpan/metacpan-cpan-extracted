use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(NAME              => 'Bio::FdrFet',
	      VERSION_FROM      => 'lib/Bio/FdrFet.pm', # finds $VERSION
	      PREREQ_PM         => { "Inline" => 0.45,
	                             "Inline::C" => 0}, # e.g., Module::Name => 1.1
	      EXE_FILES         => [ 'fdr-fet.pl' ],
	      ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
	       (ABSTRACT_FROM  => 'lib/Bio/FdrFet.pm', # retrieve abstract from module
		AUTHOR         => join(', ',
				       'Robert Bruccoleri <bruc@acm.org>',
				       'Ruiru Ji <ruiru.ji@bms.com>',
				       'Karl-Heinz Ott <karl-heinz.ott@bms.com>',
				       'Roumyana Yordanova <roumyana.yordanova@bms.com>'))
		: ()),
	      );
