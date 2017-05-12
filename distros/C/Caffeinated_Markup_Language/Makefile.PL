use 5.010001;

use strict;
use warnings;

use Config;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME		=> 'Caffeinated_Markup_Language',
	VERSION		=> '0.11.1',
	ABSTRACT	=> 'Panda blog orientated markup',
	AUTHOR		=> 'J Gregory <john@johngregory.me.uk>',
	LICENSE		=> 'artistic_2',
	PREREQ_PM	=> {
		'Moo'	   	   => '1.003001',
		'boolean'  	   => '0.30',
		'Readonly' 	   => '1.03',
		'HTML::Escape' 	   => '1.08',
		'Log::Log4perl'	   => '1.42',
	},
	BUILD_REQUIRES => {
		"Test::More" 	  => '0.99',
		"Test::Exception" => '0.32'
	},
	test 			=> {
		TESTS	=> 't/*.t'
	},
	'dist'          => { COMPRESS => "gzip -9", SUFFIX => "gz" },
);
