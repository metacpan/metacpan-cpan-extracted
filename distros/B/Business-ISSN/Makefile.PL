# $Id: Makefile.PL,v 1.4 2004/07/04 17:04:17 comdog Exp $
use ExtUtils::MakeMaker;

require 5.006;

eval "use Test::Manifest 1.14";

WriteMakefile(
	'NAME'	       => 'Business::ISSN',
	'ABSTRACT'     => 'Work with International Standard Serial Numbers',
	'VERSION_FROM' => 'lib/ISSN.pm',
	'LICENSE'      => 'perl',
	'AUTHOR'       => 'brian d foy <bdfoy@cpan.org>',
	
	'PREREQ_PM'    => { 
		'Test::More' => '0',
		},

	'PM'           => {
		'lib/ISSN.pm'         => '$(INST_LIBDIR)/ISSN.pm',
		},

	'MAN3PODS'     => {
		'lib/ISSN.pm' => '$(INST_MAN3DIR)/Business-ISSN.3',
		},

	clean  => { FILES    => q|Business-* cover_db *.old *.bak| },

	);
