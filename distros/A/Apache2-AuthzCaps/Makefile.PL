use ExtUtils::MakeMaker;

WriteMakefile(
	NAME             => 'Apache2::AuthzCaps',
	VERSION_FROM     => 'lib/Apache2/AuthzCaps.pm',
	ABSTRACT_FROM    => 'lib/Apache2/AuthzCaps.pm',
	AUTHOR           => 'Marius Gavrilescu <marius@ieval.ro>',
	MIN_PERL_VERSION => '5.14.0',
	LICENSE          => 'perl',
	SIGN             => 1,
	PREREQ_PM        => {
		qw/YAML::Any 0/,
	},
	META_MERGE       => {
		dynamic_config => 0,
		recommends   => {
			qw/Apache2::RequestRec 0/,
		},
		resources      => {
			repository => 'https://git.ieval.ro/?p=apache2-authzcaps.git',
		}
	}
);
