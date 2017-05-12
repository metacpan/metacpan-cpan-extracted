use ExtUtils::MakeMaker;

require 5.008;

eval "use Test::Manifest 1.21";

WriteMakefile(
	'NAME'	       => 'Brick',
	'ABSTRACT'     => 'Complex business rule data validation',

	'VERSION_FROM' => 'lib/Brick.pm',
	'LICENSE'      => 'perl',
	'AUTHOR'       => 'brian d foy <bdfoy@cpan.org>',
	
	'PREREQ_PM'    => { 
		'Test::Data'     => '0',
		'Test::More'     => '0',
		'Test::Output'   => '0',
		'DateTime'       => '0.36',
		'Test::Manifest' => '1.14',
		'Storable'       => '0',
		'MIME::Types'    => '0',
		'File::MMagic'   => '0',
		},

	clean  => { FILES    => q|Brick-*| },

	);
