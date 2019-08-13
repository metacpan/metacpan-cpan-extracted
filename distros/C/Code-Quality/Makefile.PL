use ExtUtils::MakeMaker;

WriteMakefile(
	NAME              => 'Code::Quality',
	VERSION_FROM      => 'lib/Code/Quality.pm',
	ABSTRACT_FROM     => 'lib/Code/Quality.pm',
	AUTHOR            => 'Marius Gavrilescu <marius@ieval.ro>',
	MIN_PERL_VERSION  => '5.20.0',
	LICENSE           => 'agpl_3',
	PREREQ_PM         => {
		qw/Cpanel::JSON::XS 0/,
	},
	TEST_REQUIRES     => {
		qw/File::Slurper  0
		   String::Escape 0/,
	},
	META_ADD          => {
		dynamic_config => 0,
		resources      => {
			repository   => {
				url  => 'https://github.com/S7012MY/CodeQuality.git',
				web  => 'https://github.com/S7012MY/CodeQuality',
				type => 'git',
			}
		},
	},
);
