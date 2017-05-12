use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(
    	NAME			=> 'Acme::Voodoo',
    	VERSION_FROM		=> 'lib/Acme/Voodoo.pm',
	PREREQ_PM		=> { },
     	ABSTRACT_FROM		=> 'lib/Acme/Voodoo.pm', 
	AUTHOR			=> 'Ed Summers <ehs@pobox.com>',
);
