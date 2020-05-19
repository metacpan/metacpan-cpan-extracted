use ExtUtils::MakeMaker;

WriteMakefile
(
	ABSTRACT_FROM		=> 'ECB.pm',
	AUTHOR			=> 'Christoph Appel',
	LICENSE			=> 'perl_5',
	MIN_PERL_VERSION	=> '5.6.0',
	NAME			=> 'Crypt::ECB',
	VERSION_FROM		=> 'ECB.pm',
);
