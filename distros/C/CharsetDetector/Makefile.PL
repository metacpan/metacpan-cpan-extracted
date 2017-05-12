require 5.004;
use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME' => 'CharsetDetector',
	'VERSION_FROM'	=>	'CharsetDetector.pm',
	'PREREQ_PM'     => {
		'Encode'=>'0',
 	},
	dist		=>	{ COMPRESS => 'gzip -9f', SUFFIX => '.gz'}
);

