use 5.014000;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME              => 'App::Scheme79asm',
	VERSION_FROM      => 'lib/App/Scheme79asm.pm',
	ABSTRACT_FROM     => 'lib/App/Scheme79asm.pm',
	MIN_PERL_VERSION  => '5.14.0',
	LICENSE           => 'perl',
	SIGN              => 1,
	PREREQ_PM         => {
		qw/Data::SExpression 0.41
		   List::MoreUtils   0.33/,
	},
	META_ADD          => {
		dynamic_config => 0,
		resources      => {
			repository   => 'https://git.ieval.ro/?p=app-scheme79asm.git',
		},
	}
);
