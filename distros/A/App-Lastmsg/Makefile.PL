use ExtUtils::MakeMaker;
use 5.014000;

WriteMakefile(
	NAME              => 'App::Lastmsg',
	VERSION_FROM      => 'lib/App/Lastmsg.pm',
	ABSTRACT_FROM     => 'lib/App/Lastmsg.pm',
	AUTHOR            => 'Marius Gavrilescu <marius@ieval.ro>',
	EXE_FILES         => [ 'lastmsg' ],
	MIN_PERL_VERSION  => '5.14.0',
	LICENSE           => 1,
	PREREQ_PM         => {
		qw/Config::Auto  0
		   Date::Parse   0
		   Email::Folder 0
		   Email::Simple 2.206/,
	},
	META_MERGE        => {
		dynamic_config => 0,
		resources      => {
			repository => 'https://git.ieval.ro/?p=app-lastmsg.git'
		}
	}
);
