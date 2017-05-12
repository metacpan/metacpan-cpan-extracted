use 5.014000;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME             => 'App::Devbot',
	VERSION_FROM     => 'lib/App/Devbot.pm',
	EXE_FILES        => [ 'devbot' ],
	ABSTRACT_FROM    => 'lib/App/Devbot.pm',
	AUTHOR           => 'Marius Gavrilescu <marius@ieval.ro>',
	MIN_PERL_VERSION => '5.14.0',
	LICENSE          => 'perl',
	SIGN             => 1,
	PREREQ_PM        => {
		qw/Getopt::Long 0
		   POSIX        0

		   File::Slurp                             0
		   IRC::Utils                              0
		   POE                                     0
		   POE::Component::IRC::Plugin::AutoJoin   0
		   POE::Component::IRC::Plugin::NickServID 0
		   POE::Component::IRC::State              0
		   Regexp::Common                          0/,
	},
	META_MERGE       => {
		dynamic_config => 0,
		recommends     => {
			qw/POE::Component::SSLify 0/,
		},
		resources      => {
			repository => 'https://git.ieval.ro/?p=app-devbot.git'
		}
	}
);
