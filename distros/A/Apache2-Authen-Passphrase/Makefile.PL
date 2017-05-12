use ExtUtils::MakeMaker;
use 5.014000;

WriteMakefile(
	NAME             => 'Apache2::Authen::Passphrase',
	VERSION_FROM     => 'lib/Apache2/Authen/Passphrase.pm',
	ABSTRACT_FROM    => 'lib/Apache2/Authen/Passphrase.pm',
	AUTHOR           => 'Marius Gavrilescu <marius@ieval.ro>',
	EXE_FILES        => [ 'aap-passwd' ],
	MIN_PERL_VERSION => '5.14.0',
	LICENSE          => 'perl',
	SIGN             => 1,
	PREREQ_PM        => {
		qw/Authen::Passphrase                0
		   Authen::Passphrase::BlowfishCrypt 0
		   IO::Prompter                      0
		   YAML::Any                         0/,
	},
	META_MERGE       => {
		recommends   => {
			qw/Apache2::RequestRec 0/,
		},
		dynamic_config => 0,
		resources      => {
			repository   => 'https://git.ieval.ro/?p=apache2-authen-passphrase.git',
		},
	}
);
