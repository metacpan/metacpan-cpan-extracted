
use ExtUtils::MakeMaker;

WriteMakefile(NAME            => 'Class::Phrasebook::Perl',
	      VERSION_FROM    => 'Perl.pm',
	      PREREQ_PM       => {},
	      ($] >= 5.005 ?
	       (ABSTRACT_FROM => 'Perl.pm',
		AUTHOR        => 'Cory Spencer <cspencer@sprocket.org>') : ())
);
