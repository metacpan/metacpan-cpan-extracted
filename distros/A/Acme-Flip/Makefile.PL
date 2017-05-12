use ExtUtils::MakeMaker;

WriteMakefile (
	NAME		=> 'Acme::Flip',
	VERSION_FROM	=> 'lib/Acme/Flip.pm',
	AUTHOR		=> 'Lubomir Rintel (lkundrak@v3.sk)',
	ABSTRACT	=> 'Replace alphanumeric characters in text with ones that look flipped',
);
