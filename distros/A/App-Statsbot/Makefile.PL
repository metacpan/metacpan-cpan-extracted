use 5.014000;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME              => 'App::Statsbot',
	VERSION_FROM      => 'lib/App/Statsbot.pm',
	ABSTRACT_FROM     => 'lib/App/Statsbot.pm',
	AUTHOR            => 'Marius Gavrilescu <marius@ieval.ro>',
	EXE_FILES         => [qw/statsbot/],
	MIN_PERL_VERSION  => '5.14.0',
	LICENSE           => 'perl',
	SIGN              => 1,
	PREREQ_PM         => {
		qw/POE::Component::IRC::State 0
		   POE                        0
		   IRC::Utils                 0
		   DBI                        0
		   DBD::SQLite                0
		   Text::ParseWords           0
		   Time::Duration             0
		   Time::Duration::Parse      0/,
	},
	META_MERGE        => {
		dynamic_config => 0,
		resources      => {
			repository => 'https://git.ieval.ro/?p=app-statsbot.git',
		}
	}
);
