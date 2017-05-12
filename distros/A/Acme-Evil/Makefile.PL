use 5.008009;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME              => 'Acme::Evil',
	VERSION_FROM      => 'lib/evil.pm',
	ABSTRACT          => 'RFC 3514 (evil bit) implementation for Perl modules',
	AUTHOR            => 'Marius Gavrilescu <marius@ieval.ro>',
	MIN_PERL_VERSION  => '5.10.1',
	LICENSE           => 'perl',
	SIGN              => 1,
	PREREQ_PM         => {},
	META_ADD         => {
		dynamic_config => 0,
		resources      => {
			repository => 'https://git.ieval.ro/?p=acme-evil.git',
		},
	}

);
