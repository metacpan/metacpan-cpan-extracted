use 5.014000;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME              => 'Algorithm::BIT::XS',
	VERSION_FROM      => 'lib/Algorithm/BIT/XS.pm',
	ABSTRACT_FROM     => 'lib/Algorithm/BIT/XS.pm',
	AUTHOR            => 'Marius Gavrilescu <marius@ieval.ro>',
	MIN_PERL_VERSION  => '5.14.0',
	LICENSE           => 'perl',
	SIGN              => 1,
	META_ADD         => {
		dynamic_config => 0,
		resources      => {
			repository   => 'https://git.ieval.ro/?p=algorithm-bit-xs.git',
		},
	}
);
