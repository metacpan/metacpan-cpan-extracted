use 5.014000;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME              => 'App::RemoteGnokii',
	VERSION_FROM      => 'lib/App/RemoteGnokii.pm',
	ABSTRACT_FROM     => 'lib/App/RemoteGnokii.pm',
	AUTHOR            => 'Marius Gavrilescu <marius@ieval.ro>',
	EXE_FILES         => [qw/rg-action rg-psgi rg-smsd/],
	MIN_PERL_VERSION  => '5.14.0',
	LICENSE           => 'gpl_3',
	SIGN              => 1,
	PREREQ_PM         => {
		qw/File::Copy 0
		   File::Temp 0

		   Config::Any    0
		   File::Slurp    0
		   File::Which    0
		   Plack::Request 0/,
	},
	META_MERGE        => {
		dynamic_config => 0,
		resources      => {
			repository => 'https://git.ieval.ro/?p=app-remotegnokii.git',
		}
	}
);
