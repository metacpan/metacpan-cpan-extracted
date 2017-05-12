use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile( 'NAME'	       => 'Config::Properties::Simple',
	       'VERSION_FROM'  => 'Simple.pm',
	       'PREREQ_PM'     => {'Config::Properties' => 0.59,
				   'Config::Find' => 0.18 },
	       'ABSTRACT_FROM' => 'Simple.pm',
	       'AUTHOR'        => 'Salvador Fandiño <sfandino@yahoo.com>' );
