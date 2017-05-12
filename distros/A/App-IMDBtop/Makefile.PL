use 5.014000;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME              => 'App::IMDBtop',
	VERSION_FROM      => 'lib/App/IMDBtop.pm',
	ABSTRACT_FROM     => 'lib/App/IMDBtop.pm',
	AUTHOR            => 'Marius Gavrilescu <marius@ieval.ro>',
	MIN_PERL_VERSION  => '5.14.0',
	LICENSE           => 'perl',
	SIGN              => 1,
	PREREQ_PM         => {
		qw/IMDB::Film 0/,
	},
	TEST_REQUIRES     => {
		qw/Test::RequiresInternet 0/
	},
	META_ADD          => {
		dynamic_config => 0,
		resources      => {
			repository   => 'https://git.ieval.ro/?p=app-imdbtop.git',
		},
	}
);
