use 5.014000;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME              => 'Convert::Base91',
	VERSION_FROM      => 'lib/Convert/Base91.pm',
	ABSTRACT_FROM     => 'lib/Convert/Base91.pm',
	AUTHOR            => 'Marius Gavrilescu <marius@ieval.ro>',
	MIN_PERL_VERSION  => '5.14.0',
	LICENSE           => 'perl',
	SIGN              => 1,
	PREREQ_PM         => {},
	INC               => '-I. -Ibase91-0.6.0',
	META_ADD         => {
		dynamic_config => 1,
		resources      => {
			repository   => 'https://git.ieval.ro/?p=convert-base91.git',
		},
	}
);
