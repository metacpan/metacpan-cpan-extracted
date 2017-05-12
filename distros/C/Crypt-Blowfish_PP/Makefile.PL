require 5.004;
use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'		=>	'Crypt::Blowfish_PP',
	'VERSION_FROM'	=>	'Blowfish_PP.pm',
	dist		=>	{ COMPRESS => 'gzip -9f', SUFFIX => 'gz'}
	);
